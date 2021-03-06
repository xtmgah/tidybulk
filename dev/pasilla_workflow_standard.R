library("pasilla")
library(reshape)
library(tidyverse)
library(tictoc)
library(ComplexHeatmap)
library(edgeR)
library(GGally)
library(sva)

### Reading data and sample annotation
pasCts = system.file("extdata",
                     "pasilla_gene_counts.tsv",
                     package = "pasilla",
                     mustWork = TRUE)
pasAnno = system.file(
  "extdata",
  "pasilla_sample_annotation.csv",
  package = "pasilla",
  mustWork = TRUE
)
cts = as.matrix(read.csv(pasCts, sep = "\t", row.names = "gene_id"))
dim(cts) # 14599     7
coldata = read.csv(pasAnno, row.names = 1)
coldata = coldata[, c("condition", "type")]
coldata$new.annot = row.names(coldata)
coldata$new.annot = gsub('fb', '', coldata$new.annot)
cts = cts[, match(coldata$new.annot, colnames(cts))]

time_df = tibble(step = "", time = list(), lines = NA, assignments = NA)

# START WORKFLOW
plot_densities = function(){

### Remving lowly expressed genes
keep1 = filterByExpr(cts, group = factor(coldata$condition))
sum(keep1)
keep2 = apply(cts, 1, function(x)  length(x[x > 5]) > 2)
sum(keep2) # 7846
cts = cts[keep2,]

### Ploting distribution of samples
col.type = c('red', 'black')[coldata$type]
col.conditions = c('blue', 'cyan')[coldata$condition]
plot(density(log2(cts[, 1] + 1)), type = 'n', ylim = c(0, .25))
for (i in 1:ncol(cts))
  lines(density(log2(cts[, i] + 1)), col = col.type[i])

### TMM normalization

dge = DGEList(counts = cts,
              sample = coldata$condition,
              group = coldata$type)
dge = calcNormFactors(dge, method = "TMM")
logCPM = cpm(dge, log = TRUE, prior.count = 0.5)
plot(density(logCPM[, 1]), type = 'n', ylim = c(0, .25))
for (i in 1:ncol(cts))
  lines(density(logCPM[, i]), col = col.type[i])

list(dge = dge, logCPM = logCPM)

}
plot_MDS = function(){

### dimensionality reduction

mds = plotMDS(logCPM, ndim = 3)
d = data.frame( 'cond' = coldata$condition,  'type' = coldata$type,  'data' = rep('CPM', 7),  'dim1' = mds$cmdscale.out[, 1],  'dim2' = mds$cmdscale.out[, 2],  'dim3' = mds$cmdscale.out[, 3])
p = ggpairs(d, columns = 4:ncol(d), ggplot2::aes(colour = type))

d
}
plot_adjusted_MDS = function(){
### ComBat

batch = coldata$type
mod.combat = model.matrix( ~ 1, data = coldata)
mod.condition = model.matrix( ~ condition, data = coldata)
combat.corrected = ComBat(  dat = logCPM,  batch = batch,  mod = mod.condition,  par.prior = TRUE,  prior.plots = FALSE)
mds.combat = plotMDS(combat.corrected, ndim = 3)
d2 = data.frame(  'cond' = coldata$condition,  'type' = coldata$type,  'data' = rep('ComBat', 7),  'dim1' = mds.combat$cmdscale.out[, 1],  'dim2' = mds.combat$cmdscale.out[, 2], 'dim3' = mds.combat$cmdscale.out[, 3])
final.d = rbind(d, d2)
final.d = gather(final.d, dim, dist, dim1:dim3, factor_key = TRUE)
final.d2 = gather(final.d, cond, type, cond:type, factor_key = TRUE)
final.d$new = paste0(final.d$cond, final.d$type)
 p = ggplot(final.d2, aes(x = cond, y = dist, fill = type)) +
  geom_boxplot() +
  facet_wrap( ~ data + dim)

combat.corrected

}
test_abundance = function(){
    # DE (comparison 1)
design = model.matrix( ~ coldata$condition + coldata$type, data = coldata$condition)
dge = estimateGLMCommonDisp(dge, design)
dge = estimateGLMTagwiseDisp(dge, design)
fit = glmFit(dge, design)
lrt = glmLRT(fit, coef = 2)
de = topTags(lrt, n = nrow(dge$counts))
#hist(de.table$PValue)

de.table  = de$table

list(
  de.table = de.table,
  de.genes = de.table[abs(de.table$logFC) >= 2,],
  de.genes.lable = de.table[abs(de.table$logFC) >= 3,]
)
}
plot_MA = function(){
  ### MA plot
n.genes = nrow(dge$counts)
gene.de = rep(NA, n.genes)
gene.de[which(row.names(de.table) %in% row.names(de.genes))] = row.names(de.genes)
gene.de.color = rep('black', n.genes)
gene.de.color[which(row.names(de.table) %in% row.names(de.genes))] = 'red'
size.point = ifelse(gene.de.color == 'black', .1, .2)
gene.lable = rep(NA, n.genes)
gene.lable[which(row.names(de.table) %in% row.names(de.genes.lable))] = row.names(de.genes.lable)
p = ggplot(de.table, aes(x = logCPM, y = logFC, label = gene.lable)) +
  geom_point(aes(
    color = gene.de.color,
    size = size.point,
    alpha = size.point
  )) +
  ggrepel::geom_text_repel()
}
plot_DE_comparative = function(){
  ### Boxplot of 6 DE genes
de.genes = row.names(de.genes.lable)[1:6]
### Raw
count.df = log2(dge$counts[de.genes ,] + 1)
colnames(count.df) = coldata$condition
count.df = melt(count.df)
count.df$data = 'count'
### cpm
cpm.df = logCPM[de.genes,]
colnames(cpm.df) = coldata$condition
cpm.df = melt(cpm.df)
cpm.df$data = 'cpm'
### combat
combat.df = combat.corrected[de.genes,]
colnames(combat.df) = coldata$condition
combat.df = melt(combat.df)
combat.df$data = 'combat'
### Boxplot of all data
final = rbind(count.df, cpm.df, combat.df)
final$data = factor(final$data, levels = c('count', 'cpm', 'combat'))
p = ggplot(final, aes(x = data, y = value, fill = X2)) +
  geom_boxplot() +
  facet_wrap( ~ X1)

de.genes
}
plot_heatmap = function(){
  ######## complex heatmap
  de.data = logCPM[de.genes ,]

  gene.labels = c(rep('AB', floor(length(de.genes)/2)), rep('BA', ceiling(length(de.genes)/2)))
  h1 = Heatmap(t(de.data), top_annotation = HeatmapAnnotation(labels = gene.labels))
  h2 = Heatmap(coldata$condition)
  h3 = Heatmap(coldata$type)
  p = draw(h1 + h2 + h3)
}

tic()
pd_res = plot_densities()
time_df = time_df %>% bind_rows(tibble(step = "Normalisation", time = list(toc()), lines = 19, assignments = 8))

logCPM = pd_res$logCPM
dge = pd_res$dge

tic()
d  = plot_MDS()
time_df = time_df %>% bind_rows(tibble(step = "Reduce dimensionality", time = list(toc()), lines = 3, assignments = 2))

tic()
combat.corrected= plot_adjusted_MDS()
time_df = time_df %>% bind_rows(tibble(step = "Removal unwanted variation", time = list(toc()), lines = 13, assignments = 10))

tic()
de_list = test_abundance()
time_df = time_df %>% bind_rows(tibble(step = "Test differential abundance", time = list(toc()), lines = 7, assignments = 6))

de.table = de_list$de.table
de.genes = de_list$de.genes
de.genes.lable = de_list$de.genes.lable

tic()
plot_MA()
time_df = time_df %>% bind_rows(tibble(step = "Plot MA", time = list(toc()), lines = 11, assignments = 8))

tic()
de.genes = plot_DE_comparative()
time_df = time_df %>% bind_rows(tibble(step = "Plot results across stages", time = list(toc()), lines = 18, assignments = 15))

tic()
plot_heatmap()
time_df = time_df %>% bind_rows(tibble(step = "Plot heatmap", time = list(toc()), lines = 6, assignments = 5))

time_df %>% mutate(step = factor(step, levels = unique(step))) %>% saveRDS("dev/stats_pasilla_standard.rds")
