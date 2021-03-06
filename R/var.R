#########################################################
### Robust variance estimation for functional snippets
#########################################################

#' Local polynomial kernel smoothing with huber loss (variance estimator)
#'
#' @param Lt a list of vectors containing time points for each curve
#' @param Ly a list of vectors containing observations for each curve
#' @param newt a vector containing time points to estimate
#' @param method "huber", "WRM" are supported
#' @param mu \code{meanfunc.rob} object from \code{meanfunc.rob()}
#' @param sig2 a noise variance estimator obtained from \code{sigma2.rob()}
#' @param kernel a kernel function for local polynomial smoothing ("epanechnikov", "gauss" are supported.)
#' @param bw a bandwidth.
#' @param delta cut-off value for "huber"(Huber) or "bisquare"(Tukey's biweight function).
#' Default is 1.345 for "huber" and 4.685 for "bisquare" for 95\% ARE.
#' @param deg a numeric scalar of polynomial degrees for local polynomial smoothing
#' @param cv If TRUE, K-fold cross-validation is performed.
#' @param ncores a number of cores to implement \code{foreach()} in \code{doParallel} for K-fold cross-validation.
#' @param cv_bw_loss a loss function for K-fold cross-validation
#' @param cv_K a number of folds for K-fold cross-validation
#' @param ... additional options
#'
#' @return a \code{varfunc.rob} object contatining \code{sig2} which is a noise variance estimate and \code{obj} which is containing as follows:
#' \item{t}{a vector containing unlist(Lt)}
#' \item{y}{a vector containing unlist(Ly)}
#' \item{n}{a number of functional trajectories}
#' \item{method}{a method used for obtaining a variance function}
#' \item{kernel}{a kernel used for local linear smoothing}
#' \item{bw}{a bandwidth}
#' \item{delta}{a cuf-off value in M-type loss function. ("HUBER")}
#' \item{deg}{a degree of polnomials}
#' \item{domain}{a range of timepoints}
#' \item{yend}{yend}
#' \item{cv_obj}{an object of K-fold CV for bandwidth}
#' \item{cv_optns}{a list containing options of K-fold cross-validation. (\code{K} = \code{cv_K}, \code{ncore} = \code{ncores}, \code{delta_loss} = \code{cv_delta_loss}, \code{bw_loss} = \code{cv_bw_loss})}
#'
#' @importFrom dplyr %>% group_by summarise
#'
#' @export
#' @useDynLib mcfda.rob
varfunc.rob <- function(Lt,
                        Ly,
                        newt = NULL,
                        method = c("L2","huber","bisquare"),
                        mu = NULL,
                        sig2 = NULL,
                        kernel = "epanechnikov",
                        bw = NULL,
                        delta = NULL,
                        deg = 1,
                        cv = FALSE,
                        ncores = 1,
                        cv_bw_loss = NULL,
                        cv_K = 5,
                        ...) {

    method <- toupper(method)
    if (!(method %in% c("L2","HUBER","WRM","BISQUARE"))) {
        stop(paste0(method, " is not provided. Check method parameter."))
    }

    # Use the same loss function to compute cross-validation error
    if (is.null(cv_bw_loss)) {
        cv_bw_loss <- method
    }

    n <- length(Lt)

    if (!(is.list(Lt) && is.list(Ly))) {
        stop("Lt and Ly must be list type.")
    }

    if (is.null(mu)) {
        mu <- meanfunc.rob(Lt = Lt,
                           Ly = Ly,
                           newt = NULL,
                           method = method,
                           kernel = kernel,
                           bw = bw,
                           delta = delta,
                           deg = deg,
                           cv = FALSE)
        # mu <- meanfunc.rob(Lt, Ly, method = method)
    }

    # calculate sum of squares
    gr <- sort(unique(unlist(Lt)))
    mu_hat <- predict(mu, gr)
    ss <- lapply(1:n, function(i) {
        ind <- match(Lt[[i]], gr)
        if (length(ind) == length(Lt[[i]])) {
            return( (Ly[[i]] - mu_hat[ind])^2 )
        } else {
            mui <- predict(mu, Lt[[i]])
            return( (Ly[[i]] - mui)^2 )
        }
    })

    # obtain noise variance
    if (is.null(sig2)) {
        h.sig2 <- select.sig2.rob.bw(Lt, Ly, ss)
        sig2 <- sigma2.rob(Lt, Ly, h = h.sig2)
    }


    R <- list(obj = meanfunc.rob(Lt = Lt,
                                 Ly = ss,
                                 newt = newt,
                                 method = method,
                                 kernel = kernel,
                                 bw = bw,
                                 delta = delta,
                                 deg = deg,
                                 cv = cv,
                                 ncores = ncores,
                                 cv_bw_loss = cv_bw_loss,
                                 cv_K = cv_K,
                                 ...),
              sig2 = sig2)
    class(R) <- 'varfunc.rob'

    if (is.null(newt)) {
        newt <- Lt
    }

    # R$fitted <- predict(R, newt)

    return(R)
}



### Predict variance at new time points
#' Predict variance at new time points
#'
#' @param object an object from \code{varfunc.rob()}
#' @param newt a vector containing timepoints to predict
#' @param ... does not needed
#'
#' @return a vector containing a variance function corresponds to \code{newt}
#'
#' @importFrom stats predict
#'
#' @export
predict.varfunc.rob <- function(object, newt, ...) {

    R <- object
    if (is.list(newt)) {
        newt <- unlist(newt)
    }
    res <- predict(R$obj, newt)
    res <- res - R$sig2

    if (sum(res < 0) > 0) {
        warning("Variance is estimated with some negative values. These are substitued to 0.")
    }
    res[res < 0] <- 0

    # ------------------------- test version ---------------------------
    # if estimated var is 0, it substitute to last value (test version)
    d <- ifelse(res == 0, 0, 1)

    ind_1 <- which(diff(d) == 1) + 1
    ind_2 <- which(diff(d) == -1)

    res[which(1:length(newt) < ind_1)] <- res[ind_1]
    res[which(1:length(newt) > ind_2)] <- res[ind_2]
    # ------------------------------------------------------------------

    if (sum(res) == 0) {
        stop("All estimated variances are 0.")
    }

    return(res)
}
