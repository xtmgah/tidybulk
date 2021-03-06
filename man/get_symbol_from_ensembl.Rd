% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions_bulk.R
\name{get_symbol_from_ensembl}
\alias{get_symbol_from_ensembl}
\title{after wget, this function merges hg37 and hg38 mapping data bases - Do not execute!}
\usage{
get_symbol_from_ensembl(.data, .ensembl)
}
\arguments{
\item{.data}{A tibble}

\item{.ensembl}{A column symbol. The column that is represents ensembl gene id}
}
\value{
A tibble with ensembl-transcript mapping

after wget, this function merges hg37 and hg38 mapping data bases - Do not execute!

A tibble with ensembl-transcript mapping

get_symbol_from_ensembl

A tibble with added annotation
}
\description{
Get transcript column from ensembl gene id
}
\keyword{internal}
