% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dca.R
\name{.dca_binary}
\alias{.dca_binary}
\title{Fit Bayesian Decision Curve Analysis using
Stan for list of models or binary tests}
\usage{
.dca_binary(
  n_thr,
  strategies,
  N,
  d,
  tp,
  tn,
  thresholds,
  prior_p1,
  prior_p2,
  prior_Se1,
  prior_Se2,
  prior_Sp1,
  prior_Sp2,
  N_ext = 0,
  d_ext = 0,
  n_draws = 4000
)
}
\arguments{
\item{n_thr}{Number of thresholds (int.).}

\item{N}{Sample size (vector of integers of length \code{n_thr}).}

\item{d}{Diseased: number of diseased persons or
events (vector of integers of length \code{n_thr}).}

\item{tp}{True Positives: number of diseased persons correctly
identified as such by the diagnostic test of prediction
model (matrix of integers of size \code{n_thr} by \code{n_strategies}).}

\item{tn}{True Negatives: number of diseased persons correctly
identified as such by the diagnostic test of prediction
model (matrix of integers of size \code{n_thr} by
\code{n_strategies}).}

\item{thresholds}{Numeric vector with probability thresholds with which
the net benefit should be computed (default is \code{seq(0.01, 0.5, 0.01)}).}

\item{N_ext, d_ext}{External sample size and number of
diseased individuals (or cases), respectively, used to
adjust prevalence.}

\item{n_strategies}{Number of models or binary tests (int.).}

\item{prior_p, prior_se, prior_sp}{Prior parameters for
prevalence, sensitivity, and specificity (numeric matrices
of size \code{n_thr} by \code{n_strategies}).}

\item{refresh}{Control verbosity of
\href{https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html}{\code{rstan::sampling}}.}

\item{...}{Arguments passed to
\href{https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html}{\code{rstan::sampling}} (e.g. iter, chains).}
}
\value{
An object of class
\href{https://mc-stan.org/rstan/reference/stanfit-class.html}{\code{stanfit}} returned by \href{https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html}{\code{rstan::sampling}} (e.g. iter, chains)
}
\description{
Fit Bayesian Decision Curve Analysis using
Stan for list of models or binary tests
}
\keyword{internal}
