my_theme =
	theme_bw() +
	theme(
		panel.border = element_blank(),
		axis.line = element_line(),
		panel.grid.major = element_line(size = 0.2),
		panel.grid.minor = element_line(size = 0.1),
		text = element_text(size=12),
		legend.position="bottom",
		aspect.ratio=1,
		strip.background = element_blank(),
		axis.title.x  = element_text(margin = margin(t = 10, r = 10, b = 10, l = 10)),
		axis.title.y  = element_text(margin = margin(t = 10, r = 10, b = 10, l = 10)),
		axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.2)
	)

stats =
	readRDS("dev/stats_pasilla_ttBulk.rds") %>%
	mutate(Method = "tidybulk") %>%
	bind_rows(
		readRDS("dev/stats_pasilla_standard.rds") %>%
		mutate(Method = "Standard")
	) %>%
	mutate(elapsed = map(time, ~ as.numeric(.x$toc - .x$tic))) %>%
	unnest(elapsed) %>%
	select(-time)

(
  stats %>%
    rename( `Number of lines` = lines, `Number of variable assignments` = assignments, `Seconds elapsed` = elapsed, Steps = step ) %>%
  	pivot_longer(names_to = ".variable", values_to = "Count", cols = c(`Number of lines`, `Number of variable assignments`, `Seconds elapsed`)) %>%
  	mutate(.variable = .variable %>% factor(levels = c( "Number of variable assignments", "Number of lines", "Seconds elapsed"))) %>%
  	ggplot(aes(x = Steps, y = Count, color = Method, group = Method)) +
  	geom_line() +
  	geom_point() +
  	facet_wrap(~.variable, scales = "free") +
    scale_color_brewer(palette = "Set1") +
  	my_theme 
) %>%
  ggsave(
    filename =	"dev/pasilla_benchmark.pdf",
    device = "pdf",
    useDingbats=FALSE,
    units = c("mm"),
    width = 183 
  )
