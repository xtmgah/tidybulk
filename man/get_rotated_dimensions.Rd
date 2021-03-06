% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions_bulk.R
\name{get_rotated_dimensions}
\alias{get_rotated_dimensions}
\title{Get rotated dimensions of two principal components or MDS dimension of choice, of an angle}
\usage{
get_rotated_dimensions(
  .data,
  dimension_1_column,
  dimension_2_column,
  rotation_degrees,
  .element = NULL,
  of_samples = TRUE,
  dimension_1_column_rotated = NULL,
  dimension_2_column_rotated = NULL
)
}
\arguments{
\item{.data}{A tibble}

\item{dimension_1_column}{A column symbol. The column of the dimension 1}

\item{dimension_2_column}{A column symbol. The column of the dimension 2}

\item{rotation_degrees}{A real number between 0 and 360}

\item{.element}{A column symbol. The column that is used to calculate distance (i.e., normally samples)}

\item{of_samples}{A boolean}

\item{dimension_1_column_rotated}{A column symbol. The column of the dimension 1 rotated}

\item{dimension_2_column_rotated}{A column symbol. The column of the dimension 2 rotated}
}
\value{
A tibble with additional rotated columns
}
\description{
Get rotated dimensions of two principal components or MDS dimension of choice, of an angle
}
\keyword{internal}
