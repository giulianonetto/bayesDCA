#' @title Compute Expected Value of Perfect Information (EVPI)
#'
#' @param obj BayesDCAList or BayesDCASurv object
#' @param ... matrices of dimension n_draws * n_thresholds
#' containing posterior net benefit
#' @importFrom magrittr %>%
#' @keywords internal
evpi <- function(thresholds, ...) {
  .dots <- list(...)
  .evpi <- numeric(length = length(thresholds))
  for (i in seq_along(thresholds)) {
    .dots_i <- lapply(.dots, function(.d) .d[, i])
    mean_nbs <- unlist(lapply(.dots_i, function(nb_draws) mean(nb_draws)))
    max_nb_draws <- matrixStats::rowMaxs(
      cbind(0, do.call(cbind, .dots_i))
    )
    ENB_perfect <- mean(max_nb_draws) # nolint
    ENB_current <- max(0, mean_nbs) # nolint
    .evpi[i] <- ENB_perfect - ENB_current
  }
  return(.evpi)
}

#' @title Get cutpoints for survival estimation
#' @param .prediction_time time point at which event is predicted to happen
#' @param .event_times times of observed events (non-censored)
#' @param .base_cutpoints vector of cutpoints to start with
#' @keywords internal
get_cutpoints <- function(.prediction_time,
                          .event_times,
                          .min_events = 10,
                          .base_cutpoints = NULL) {
  stopifnot("All event times must be positive." = all(.event_times > 0))
  if (is.null(.base_cutpoints)) {
    .base_cutpoints <- seq(
      0.1, 1,
      length = 15
    ) * .prediction_time
  }
  .base_cutpoints <- .base_cutpoints[.base_cutpoints > 0]
  events_above_cutpoint <- sapply(
    .base_cutpoints, function(cutpoint) sum(.event_times > cutpoint)
  )
  .base_cutpoints <- .base_cutpoints[events_above_cutpoint >= .min_events]
  # only keep cutpoints that correspond to
  # intervals with at least `.min_events` events
  .previous <- new_cutpoints <- 0
  for (i in seq_along(.base_cutpoints)) {
    .current <- .base_cutpoints[i]
    events <- sum(.event_times > .previous & .event_times <= .current)
    if (events >= .min_events) {
      new_cutpoints <- c(new_cutpoints, .current)
      .previous <- .current
    }
  }

  return(new_cutpoints)
}

#' @title Get events per intervals defined by set of cutpoints
#' @param .cutpoints cutpoints defining intervals
#' @param .event_times times of observed events (non-censored)
#' @keywords internal
get_events_per_interval <- function(.cutpoints, .event_times) {
  table(cut(.event_times, c(.cutpoints, Inf)))
}


#' @title Get colors and labels for BayesDCA plots
#'
#' @param obj BayesDCAList object
#' @param colors Named vector with color for each model or test. If provided
#' for a subset of models or tests, only that subset will be plotted.
#' @param labels Named vector with label for each model or test.
#' @importFrom magrittr %>%
#' @keywords internal
get_colors_and_labels <- function(obj,
                                  strategies = NULL,
                                  colors = NULL, labels = NULL,
                                  all_or_none = TRUE) {
  # decide which models/tests to include
  if (is.null(strategies)) {
    strategies <- obj$strategies
  } else {
    stopifnot(
      any(strategies %in% obj$strategies)
    )
    strategies <- strategies[
      strategies %in% obj$strategies
    ]
  }
  # pick color palette for ggplot
  if (isTRUE(all_or_none)) {
    color_values <- c(
      "Treat all" = "black", "Treat none" = "gray40"
    )
  } else {
    color_values <- character()
  }

  n_colors <- length(strategies)
  if (n_colors < 9) {
    palette <- RColorBrewer:::brewer.pal(max(c(n_colors, 3)), "Dark2")
  } else {
    palette <- grDevices::colorRampPalette(
      RColorBrewer:::brewer.pal(n_colors, "Set2")
    )(n_colors)
  }
  # set actual color values to use in scale_color_manual
  for (i in seq_len(n_colors)) {
    decision_strategy <- strategies[i]
    if (!is.null(colors) && decision_strategy %in% names(colors)) {
      color_values[decision_strategy] <- colors[[decision_strategy]]
    } else {
      color_values[decision_strategy] <- palette[i]
    }
  }
  # define color and label scales
  if (is.null(labels)) {
    colors_and_labels <- list(
      ggplot2::scale_color_manual(
        values = color_values
      ),
      ggplot2::scale_fill_manual(
        values = color_values
      )
    )
  } else {
    colors_and_labels <- list(
      ggplot2::scale_color_manual(
        labels = labels, values = color_values
      ),
      ggplot2::scale_fill_manual(
        labels = labels, values = color_values
      )
    )
  }

  return(colors_and_labels)
}

#' @title Get time exposed within each interval for a given prediction time
#'
#' @param .prediction_time Time for event prediction
#' @param .cutpoints Cutpoints for constant hazard interval
#' @keywords internal
get_survival_time_exposed <- function(.prediction_time, .cutpoints) {
  time_exposed <- numeric(length = length(.cutpoints))
  for (i in seq_len(length(.cutpoints))) {
    .lower <- .cutpoints[i]
    .upper <- c(.cutpoints, Inf)[i + 1]
    if (.prediction_time > .upper) {
      # if prediction time > upper bound, use interval length
      time_exposed[i] <- .upper - .lower
    } else if (.prediction_time > .lower) {
      # if prediction time > lower bound,
      # use distance between pred time and lower bound
      time_exposed[i] <- .prediction_time - .lower
    } else {
      # otherwise, prediction time is before interval, exposure time is zero
      time_exposed[i] <- 0
    }
  }
  return(time_exposed)
}

#' @title Get posterior parameters for positivity probability
#'
#' @param .prediction_data Contains prognostic model predictions
#' @param .thresholds DCA thresholds.
#' @param .prior_shape1 Shape 1 for beta prior.
#' @param .prior_shape2 Shape 2 for beta prior.
#' @keywords internal
get_positivity_posterior_parameters <- function(.prediction_data, # nolint
                                                .thresholds,
                                                .prior_shape1 = 1,
                                                .prior_shape2 = 1,
                                                .prior_only = FALSE) {
  N <- nrow(.prediction_data) # nolint
  n_models <- ncol(.prediction_data)
  .strategies <- colnames(.prediction_data)
  n_thresholds <- length(.thresholds)

  all_posterior_shape1 <- matrix(
    nrow = n_models,
    ncol = n_thresholds
  )
  all_posterior_shape2 <- matrix(
    nrow = n_models,
    ncol = n_thresholds
  )

  for (i in seq_along(.strategies)) {
    .model <- .strategies[i]
    for (j in seq_along(.thresholds)) {
      if (isFALSE(.prior_only)) {
        .thr <- .thresholds[j]
        .predictions <- .prediction_data[[.model]]
        .positive_prediction <- .predictions >= .thr
        total_positives <- sum(.positive_prediction)
        all_posterior_shape1[i, j] <- total_positives + .prior_shape1
        all_posterior_shape2[i, j] <- N - total_positives + .prior_shape2
      } else {
        all_posterior_shape1[i, j] <- .prior_shape1
        all_posterior_shape2[i, j] <- .prior_shape2
      }
    }
  }

  .posterior_pars <- list(
    .shape1 = all_posterior_shape1,
    .shape2 = all_posterior_shape2
  )
  return(.posterior_pars)
}

#' @title Get priors for Bayesian DCA
#'
#' @param thresholds Vector of decision thresholds.
#' @param shift Scalar controlling height of prior
#' Specificity curve. Only used if `constant=FALSE`.
#' @param slope Scalar controlling shape of prior
#' Specificity curve. Only used if `constant=FALSE`.
#' @param min_mean_se,min_mean_sp,max_mean_se,max_mean_se Minimum
#' @param prior_sample_size Prior sample size of strength.
#' @param min_prior_sample_size Minimum prior sample size or strength.
#' @param max_prior_sample_size Maximum prior sample size or strength.
#' @param slope_prior_sample_size Rate of change in prior
#' sample size or strength.
#' and maximum prior mean for sensitivity (se) and specificity (sp).
#' @importFrom magrittr %>%
#' @keywords internal
.get_prior_parameters <- function(thresholds,
                                  threshold_varying_prior = FALSE,
                                  n_strategies = NULL,
                                  prior_p = NULL,
                                  prior_se = NULL,
                                  prior_sp = NULL,
                                  ignorance_region_cutpoints = c(0.25, 0.75) * max(thresholds),
                                  min_sens_prior_mean = 0.01,
                                  max_sens_prior_mean = 0.99,
                                  max_sens_prior_sample_size = 5,
                                  ignorance_region_mean = 0.5,
                                  ignorance_region_sample_size = 2,
                                  prev_prior_mean = 0.5,
                                  prev_prior_sample_size = 2) {
  if (isFALSE(threshold_varying_prior)) {
    .priors <- .get_constant_prior_parameters(
      prior_p = prior_p,
      prior_se = prior_se,
      prior_sp = prior_sp,
      n_thresholds = length(thresholds),
      n_strategies = n_strategies
    )
  } else {
    .priors <- .get_threshold_varying_prior_parameters(
      thresholds = thresholds,
      n_strategies = n_strategies,
      ignorance_region_cutpoints = ignorance_region_cutpoints,
      min_sens_prior_mean = min_sens_prior_mean,
      max_sens_prior_mean = max_sens_prior_mean,
      max_sens_prior_sample_size = max_sens_prior_sample_size,
      ignorance_region_mean = ignorance_region_mean,
      ignorance_region_sample_size = ignorance_region_sample_size,
      prev_prior_mean = prev_prior_mean,
      prev_prior_sample_size = prev_prior_sample_size
    )
  }

  return(.priors)
}

#' @title Get constant priors for Bayesian DCA
#'
#' @param n_thresholds Number of thresholds (int.).
#' @param n_strategies Number of models or tests (int.).
#' @param prior_p,prior_se,prior_sp Non-negative shape values for
#' Beta(alpha, beta) priors used for p, Se, and Sp, respectively.
#' Default is uniform prior for all parameters - Beta(1, 1).
#' A single vector of the form `c(a, b)` can be provided for each.
#' @importFrom magrittr %>%
#' @keywords internal
.get_constant_prior_parameters <- function(n_thresholds,
                                           n_strategies,
                                           prior_p = NULL,
                                           prior_se = NULL,
                                           prior_sp = NULL) {
  if (is.null(prior_p)) prior_p <- c(1, 1)
  if (is.null(prior_se)) prior_se <- c(1, 1)
  if (is.null(prior_sp)) prior_sp <- c(1, 1)

  stopifnot(
    length(prior_p) == 2 & is.vector(prior_p)
  )
  stopifnot(
    length(prior_se) == 2 & is.vector(prior_se)
  )
  stopifnot(
    length(prior_sp) == 2 & is.vector(prior_sp)
  )

  se1 <- matrix(
    sapply(1:n_strategies, function(i) rep(prior_se[1], n_thresholds)),
    ncol = n_strategies,
    nrow = n_thresholds
  )
  se2 <- matrix(
    sapply(1:n_strategies, function(i) rep(prior_se[2], n_thresholds)),
    ncol = n_strategies,
    nrow = n_thresholds
  )
  sp1 <- matrix(
    sapply(1:n_strategies, function(i) rep(prior_sp[1], n_thresholds)),
    ncol = n_strategies,
    nrow = n_thresholds
  )
  sp2 <- matrix(
    sapply(1:n_strategies, function(i) rep(prior_sp[2], n_thresholds)),
    ncol = n_strategies,
    nrow = n_thresholds
  )

  .priors <- list(
    p1 = prior_p[1],
    p2 = prior_p[2],
    Se1 = se1, Se2 = se2,
    Sp1 = sp1, Sp2 = sp2
  )
  return(.priors)
}


#' @title Get threshold-varying priors for Bayesian DCA
#' @importFrom magrittr %>%
#' @keywords internal
.get_threshold_varying_prior_parameters <- function(
    thresholds, # nolint
    n_strategies,
    ignorance_region_cutpoints = c(0.25, 0.75) * max(thresholds),
    min_sens_prior_mean = 0.01,
    max_sens_prior_mean = 0.99,
    max_sens_prior_sample_size = 5,
    ignorance_region_mean = 0.5,
    ignorance_region_sample_size = 2,
    prev_prior_mean = 0.5,
    prev_prior_sample_size = 2) {
  min_t <- min(thresholds)
  max_t <- max(thresholds)
  if (!is.null(ignorance_region_cutpoints)) {
    stopifnot("if given, ignorance_region_cutpoints should be 2D vector within thresholds range" = length(ignorance_region_cutpoints) == 2 && min(ignorance_region_cutpoints) >= min_t && max(ignorance_region_cutpoints) <= max_t) # nolint
  }
  .lengths <- sapply(
    c(
      min_sens_prior_mean, max_sens_prior_mean, max_sens_prior_sample_size
    ),
    length
  )
  stopifnot("All sensitivity parameters must have length equal either to 1 or to n_strategies" = all(.lengths == 1L) | all(.lengths == n_strategies))
  if (.lengths[1] == 1L) {
    min_sens_prior_mean <- rep(min_sens_prior_mean, length = n_strategies)
    max_sens_prior_mean <- rep(max_sens_prior_mean, length = n_strategies)
    max_sens_prior_sample_size <- rep(max_sens_prior_sample_size, length = n_strategies)
  }

  n_thresholds <- length(thresholds)
  .priors <- list(
    p1 = prev_prior_mean * prev_prior_sample_size,
    p2 = (1 - prev_prior_mean) * prev_prior_sample_size,
    Se1 = matrix(nrow = n_thresholds, ncol = n_strategies),
    Se2 = matrix(nrow = n_thresholds, ncol = n_strategies),
    Sp1 = matrix(nrow = n_thresholds, ncol = n_strategies),
    Sp2 = matrix(nrow = n_thresholds, ncol = n_strategies),
    summaries = list(
      p = list(
        mean = prev_prior_mean,
        sample_size = prev_prior_sample_size,
        lower = qbeta(0.025, prev_prior_mean * prev_prior_sample_size, (1 - prev_prior_mean) * prev_prior_sample_size),
        upper = qbeta(0.975, prev_prior_mean * prev_prior_sample_size, (1 - prev_prior_mean) * prev_prior_sample_size)
      ),
      Se = lapply(
        seq_len(n_strategies), function(...) {
          matrix(
            nrow = n_thresholds, ncol = 4,
            dimnames = list(NULL, c("mean", "sample_size", "lower", "upper"))
          )
        }
      ),
      Sp = lapply(
        seq_len(n_strategies), function(...) {
          matrix(
            nrow = n_thresholds, ncol = 4,
            dimnames = list(NULL, c("mean", "sample_size", "lower", "upper"))
          )
        }
      )
    )
  )

  cuts <- ignorance_region_cutpoints # OK, I agree these names are a bit too big
  for (m in seq_len(n_strategies)) {
    for (j in seq_along(thresholds)) {
      .t <- thresholds[j]
      if (!is.null(cuts)) {
        if (.t <= cuts[1]) {
          sens_mean <- max_sens_prior_mean[m] + (.t - min_t) * (ignorance_region_mean - max_sens_prior_mean[m]) / (cuts[1] - min_t)
          smpl_size <- max_sens_prior_sample_size[m] + (.t - min_t) * (ignorance_region_sample_size - max_sens_prior_sample_size[m]) / (cuts[1] - min_t)
        } else if (.t <= cuts[2]) {
          sens_mean <- ignorance_region_mean
          smpl_size <- ignorance_region_sample_size
        } else {
          sens_mean <- ignorance_region_mean + (.t - cuts[2]) * (min_sens_prior_mean[m] - ignorance_region_mean) / (max_t - cuts[2])
          smpl_size <- ignorance_region_sample_size + (.t - cuts[2]) * (max_sens_prior_sample_size[m] - ignorance_region_sample_size) / (max_t - cuts[2])
        }
      } else {
        sens_mean <- max_sens_prior_mean[m] + (.t - min_t) * (min_sens_prior_mean[m] - max_sens_prior_mean[m]) / (max_t - min_t)
        smpl_size <- max_sens_prior_sample_size[m]
      }
      sens_mean <- max(min(sens_mean, 0.999), 0.001)
      spec_mean <- 1 - sens_mean
      .priors[["Se1"]][j, m] <- sens_mean * smpl_size
      .priors[["Se2"]][j, m] <- (1 - sens_mean) * smpl_size
      .priors[["Sp1"]][j, m] <- spec_mean * smpl_size
      .priors[["Sp2"]][j, m] <- (1 - spec_mean) * smpl_size
      .priors[["summaries"]][["Se"]][[m]][j, "mean"] <- sens_mean
      .priors[["summaries"]][["Se"]][[m]][j, "sample_size"] <- smpl_size
      .priors[["summaries"]][["Se"]][[m]][j, "lower"] <- qbeta(
        0.025,
        shape1 = .priors[["Se1"]][j, m], shape2 = .priors[["Se2"]][j, m]
      )
      .priors[["summaries"]][["Se"]][[m]][j, "upper"] <- qbeta(
        0.975,
        shape1 = .priors[["Se1"]][j, m], shape2 = .priors[["Se2"]][j, m]
      )
      .priors[["summaries"]][["Sp"]][[m]][j, "mean"] <- spec_mean
      .priors[["summaries"]][["Sp"]][[m]][j, "sample_size"] <- smpl_size
      .priors[["summaries"]][["Sp"]][[m]][j, "lower"] <- qbeta(
        0.025,
        shape1 = .priors[["Sp1"]][j, m], shape2 = .priors[["Sp2"]][j, m]
      )
      .priors[["summaries"]][["Sp"]][[m]][j, "upper"] <- qbeta(
        0.975,
        shape1 = .priors[["Sp1"]][j, m], shape2 = .priors[["Sp2"]][j, m]
      )
    }
  }

  return(.priors)
}

validate_strategies <- function(obj,
                                strategies = NULL) {
  if (is.null(strategies)) {
    strategies <- as.vector(na.omit(obj$strategies))
  } else {
    stopifnot(
      "Provided `strategies` are not available" = all(
        strategies %in% obj$strategies
      )
    )
  }

  return(strategies)
}
