% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{.get_constant_prior_parameters}
\alias{.get_constant_prior_parameters}
\title{Get constant priors for Bayesian DCA}
\usage{
.get_constant_prior_parameters(
  n_thresholds,
  n_strategies,
  prior_p = NULL,
  prior_se = NULL,
  prior_sp = NULL
)
}
\arguments{
\item{n_thresholds}{Number of thresholds (int.).}

\item{n_strategies}{Number of models or tests (int.).}

\item{prior_p, prior_se, prior_sp}{Non-negative shape values for
Beta(alpha, beta) priors used for p, Se, and Sp, respectively.
Default is uniform prior for all parameters - Beta(1, 1).
A single vector of the form \code{c(a, b)} can be provided for each.}
}
\description{
Get constant priors for Bayesian DCA
}
\keyword{internal}
