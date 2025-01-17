% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dca.R
\name{.extract_dca_summary}
\alias{.extract_dca_summary}
\title{Get summary from BayesDCA fit}
\usage{
.extract_dca_summary(fit, strategies, summary_probs, thresholds)
}
\arguments{
\item{fit}{A stanfit object.}

\item{strategies}{Vector of names of models or binary tests under assessment.}

\item{summary_probs}{Numeric vector giving probabilities for credible interval.}

\item{thresholds}{Vector of thresholds for DCA.}
}
\description{
Get summary from BayesDCA fit
}
\keyword{internal}
