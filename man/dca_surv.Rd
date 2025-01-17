% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dca_surv.R
\name{dca_surv}
\alias{dca_surv}
\title{Bayesian Decision Curve Analysis
for Survival outcomes}
\usage{
dca_surv(
  .data,
  prediction_time,
  thresholds = seq(0, 0.5, length = 51),
  keep_draws = TRUE,
  keep_fit = FALSE,
  summary_probs = c(0.025, 0.975),
  positivity_prior = c(1, 1),
  shape_prior = c("student", "gamma"),
  scale_prior = c("student", "gamma"),
  shape_prior_pars = c(10, 0, 1.5),
  scale_prior_pars = c(30, 0, 100),
  prior_only = FALSE,
  iter = 4000,
  refresh = 0,
  ...
)
}
\arguments{
\item{.data}{dataframe whose first column named "outcomes" is a \code{survival::Surv} object
and remaining columns are the decision strategies to assess.}

\item{prediction_time}{Prediction time horizon (e.g., if models predict risk
of death at one year and data is in year, \code{prediction_time} should be \code{1}.)}

\item{thresholds}{Decision thresholds -- within interval (0, 1).}

\item{keep_draws}{If true, posterior draws are kept in the output object.}

\item{keep_fit}{If true, \code{stanfit} object is kept in the output object.}

\item{summary_probs}{Probabilities for posterior credible intervals (defaults to a 95\% Cr.I.).}

\item{positivity_prior}{Shape parameters for prior on positivity probability.}

\item{shape_prior}{type of prior distribution for shape parameter of the Weibull distribution. Either "student" or "gamma".}

\item{scale_prior}{type of prior distribution for scale parameter of the Weibull distribution. Either "student" or "gamma".}

\item{shape_prior_pars}{vector with prior parameters for the prior shape of the Weibull distribution.
If \code{shape_prior="student"}, it should be a vector of length 3 with degrees of freedom, mean, and scale,
respectively; if \code{shape_prior="gamma"}, it should be a vector of length 2 with shape and rate, respectively.}

\item{prior_only}{If TRUE, samples from the prior only.}

\item{iter}{Passed to \href{https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html}{\code{rstan::sampling}}. Number of iterations/draws for Stan.}

\item{refresh}{Controls verbosity of
\href{https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html}{\code{rstan::sampling}}}

\item{...}{Arguments passed to
\href{https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html}{\code{rstan::sampling}} (e.g. iter, chains).  # nolint}
}
\value{
An object of class \code{BayesDCASurv}
}
\description{
Bayesian Decision Curve Analysis
for Survival outcomes
}
\examples{
\dontrun{
data(dca_survival_data)
fit <- dca_surv(dca_survival_data, prediction_time = 1, iter = 1000, chains = 1)
plot(fit)
}
}
