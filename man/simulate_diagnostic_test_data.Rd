% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fake_data_simulation.R
\name{simulate_diagnostic_test_data}
\alias{simulate_diagnostic_test_data}
\title{Simulate Diagnostic Test Data}
\usage{
simulate_diagnostic_test_data(
  B = 100,
  N = 500,
  true_p = 0.2,
  true_se = 0.9,
  true_sp = 0.9,
  keep_true_pars = FALSE
)
}
\arguments{
\item{B}{Integer indicating number of simulated datasets.}

\item{N}{Integer indicating sample size in each dataset.}

\item{true_p}{Proportion indicating true prevalence in each dataset.}

\item{true_se}{Proportion indicating true sensitivity in each dataset.}

\item{true_sp}{Proportion indicating true specificity in each dataset.}

\item{keep_true_pars}{Logical indicating whether to keep true
parameter values in the output dataframe.}
}
\value{
A Bx7 data frame with simulated data and provided parameters.
}
\description{
Simulate Diagnostic Test Data
}
\details{
Diagnostic test data is simulated according to the following
mechanism: for each of the \code{B} simulations, \code{d} \emph{diseased} persons
are sampled from a binomial of size \code{N} and parameter \code{true_p}. Then,
\code{tp} \emph{true positive} outcomes are sampled from a binomial of size \code{d}
and parameter \code{true_se}, and \code{tn} \emph{true negative} outcomes are
sampled from a binomial of size \code{N-d} with parameter \code{true_sp}. This
simulates \code{B} diagnostic accuracy studies in which a number of
diseased and non-diseased persons are sampled from a population;
the expected proportion of diseased persons correctly detected as
such is the sensitivity, and the number of non-diseased persons
correctly detected as such is the specificity.
}
\examples{
d <- simulate_diagnostic_test_data(B = 2,
                                   N = 1000,
                                   true_p = 0.2,
                                   true_se = 0.9,
                                   true_sp = 0.9)
head(d)
}
\keyword{internal}
