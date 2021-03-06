% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cov_local_M.R
\name{cv.cov_local_M}
\alias{cv.cov_local_M}
\title{Robust K-fold Cross-Validation for the Optimal Bandwidth of Bivariate Local M-estimator for Covariance function}
\usage{
cv.cov_local_M(
  X,
  bw_cand = NULL,
  mu = NULL,
  K = 5,
  ncores = 1,
  delta = 1.345,
  engine = "C++"
)
}
\arguments{
\item{X}{a n x p matrix}

\item{bw_cand}{a numeric vector of bandwidth candidate. (Default is \code{NULL}, and it is selected automatically.)}

\item{mu}{a numeric vector of mean function. If it is \code{NULL}, robust 5-fold CV is performed for estimating mean function. (Default is \code{NULL}.)}

\item{K}{a number of folds for K-fold cross-validation. (Default is 5.)}

\item{ncores}{a number of cores to select bandwidth from robust 5-fold cross-validation. (Defalut is 1.)}

\item{delta}{a cut-off value in Huber loss function. (Default is 1.345.)}

\item{engine}{the option for implementation. (Defalut is \code{C++}, and it is much faster than \code{R}.)}
}
\value{
a list contatining as follows:
\item{selected_bw}{the optimal bandwidth selected from the robust K-fold cross-validation.}
\item{cv.error}{a matrix containing CV error per bandwidth candidates.}
}
\description{
Perform robust K-fold cross-validation to select the optimal bandwidth of bivariate local M-estimator for covariance function.
}
\details{
It provides 2 options for implementing R or C++.
}
