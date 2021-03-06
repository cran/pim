#' Fitting a Probabilistic Index Model
#'
#' This function fits a probabilistic index model,
#' also known as PIM. It can be used to fit standard PIMs, as well as
#' many different flavours of models that can be reformulated as a pim.
#' The most general models are implemented, but the flexible formula
#' interface allows you to specify a wide variety of different models.
#'
#' PIMs are based on a set of pseudo-observations constructed from the
#' comparison between a range of possible combinations of 2 observations.
#' We call the set of pseudo observations \emph{poset} in the context
#' of this package.
#'
#' By default, this poset takes every unique combination of 2 observations
#' (\code{compare = "unique"}). You can either use a character value, or
#' use a matrix or list to identify the set of observation pairs that have to be
#' used as pseudo-observations. Note that the matrix and list should
#' be either nameless, or have the (col)names 'L' and 'R'. If any other
#' names are used, these are ignored and the first column/element
#' is considered to be 'L'. See also
#' \code{\link{new.pim.poset}}.
#'
#' It's possible to store the model matrix and psuedo responses in the
#' resulting object. By default this is not done
#' (\code{keep.data = FALSE}) as this is less burden on the memory and
#' the \code{\link{pim.formula}} object contains all information to
#' reconstruct both the model matrix and the pseudo responses.
#' If either the model matrix or the pseudo responses are needed for
#' further calculations, setting \code{keep.data} to \code{TRUE} might
#' reduce calculation time for these further calculations.
#'
#' @section The enhanced formula interface:
#' In case you want to fit a standard PIM, you can specify the model in
#' mostly the same way as for \code{\link[stats]{lm}}. There's one important
#' difference: a PIM has by default no intercept. To add an intercept, use
#' \code{+ 1} in the formula.
#'
#' Next to this, you can use the functions \code{\link{L}} and \code{\link{R}}
#' in a formula to indicate which part of the poset you refer to. Remember a
#' poset is essentially a matrix-like object with indices refering to the
#' pseudo-observations. Using \code{L()} and \code{R()} you can define
#' exactly how the pseudo-observations fit in the model. Keep in mind that
#' any calculation done with these functions, has to be wrapped in a call
#' to \code{I()}, just like you would do in any other formula interface.
#'
#' You don't have to specify the model though. If you choose the option
#' \code{model = 'difference'}, every variable in the formula will be
#' interpreted as \code{I(R(x) - L(x))}. If you use the option
#' \code{model = 'marginal'}, every variable will be interpreted as
#' \code{R(X)}.
#'
#' If you don't specify any special function (i.e. \code{\link{L}},
#' \code{\link{R}}, \code{\link{P}} or \code{\link{PO}}),
#' the lefthand side of the formula is defined as \code{PO(y)}. The function
#' \code{\link{PO}} calculates pseudo observations; it is 1
#' if the value of the dependent variable for the observation
#' from the L-poset is smaller than, 0 if it is larger than and 0.5 if
#' it is equal to the value for value from the R-poset (see also \code{\link{PO}})
#'
#' @param formula An object of class \code{\link{formula}} (or one that
#' can be coerced to that class): A symbolic description of the model
#' to be fitted. The details of model specification are given under 'Details'.
#'
#' @param data an optional data frame, list or environment that contains
#' the variables in the model. Objects that can be coerced by
#' \code{\link{as.data.frame}} can be used too.
#'
#' @param link a character vector with a single value that determines the
#' used link function. Possible values are "logit", "probit" and "identity".
#' The default is "logit".
#'
#' @param compare a character vector with a single value that describes how the
#' model compares observations. It can take the values "unique" or "all".
#' Alternatively you can pass a matrix with two columns.
#' Each row represents the rownumbers in the original data frame that
#' should be compared to eachother. See Details.
#'
#' @param model a single character value with possible values "difference"
#' (the default), "marginal", "regular" or "customized". If the formula indicates
#' a customized model (by the use of \code{\link{L}()} or \code{\link{R}()}),
#' this parameter is set automatically to "customized". Currently, only the
#' options "difference", "marginal" and "customized" are implemented.
#'
#' @param na.action the name of a function which indicates what should happen when the data
#' contains NAs. The default is set by the \code{na.action} setting of
#' \code{\link{options}}, and is \code{\link{na.fail}} when unset.
#'
#' @param keep.data a logical value indicating whether the model
#' matrix should be saved in the object. Defaults to \code{FALSE}. See Details.
#'
#' @param weights Currently not implemented.
#'
#' @param ... extra parameters sent to \code{\link{pim.fit}}
#'
#' @return An object of class \code{pim}. See \code{\link{pim-class}}
#' for more information.
#'
#' @seealso \code{\link{pim-class}} for more information on the returned
#' object, \code{\link{pim.fit}} for more information on the fitting
#' itself,  \code{\link{pim-getters}}, \code{\link{coef}}, \code{\link{confint}},
#' \code{\link{vcov}} etc  for how to extract information like coefficients,
#' variance-covariance matrix, ...,
#' \code{\link{summary}} for some tests on the coefficients.
#'
#' @examples
#' data('FEVData')
#' # The most basic way to use the function
#' Model <- pim(FEV~ Smoke*Sex , data=FEVData)
#'
#' # A model with intercept
#' # The argument xscalm is passed to nleqslv via pim.fit and estimator.nleqslv
#' # By constructing the estimator functions wisely, you can control most of
#' # the fitting process from the pim() function.
#' data('EngelData')
#' Model2 <- pim(foodexp ~ income + 1, data=EngelData,
#'    compare="all",
#'    xscalm = 'auto')
#'
#' # A marginal model
#' # It makes sense to use the identity link in combination with the
#' # score estimator for the variance-covariance matrix
#' data('DysData')
#' Model3 <- pim(SPC_D2 ~ out, data = DysData,
#'   model = 'marginal', link = 'identity',
#'   vcov.estim = score.vcov)
#'
#' # A Model using logical comparisons, this is also possible!
#' # Model the chance that both observations have a different
#' # outcome in function of whether they had a different Chemo treatment
#' Model6 <- pim(P(L(out) != R(out)) ~ I(L(Chemo) != R(Chemo)),
#'    data=DysData,
#'    compare="all")
#'
#' # Implementation of the friedman test in the context of a pim
#' # warpbreaks data where we consider tension as a block
#' # To do so, you provide the argument compare with a custom
#' # set of comparisons
#' data(warpbreaks)
#' wb <- aggregate(warpbreaks$breaks,
#'                 by = list(w = warpbreaks$wool,
#'                           t = warpbreaks$tension),
#'                 FUN = mean)
#' comp <- expand.grid(1:nrow(wb), 1:nrow(wb))
#' comp <- comp[wb$t[comp[,1]] == wb$t[comp[,2]],] # only compare within blocks
#' m <- pim(x ~ w, data = wb, compare = comp, link = "identity",  vcov.estim = score.vcov)
#' summary(m)
#' friedman.test(x ~ w | t, data = wb)
#' \dontrun{
#' # This illustrates how a standard model is actually built in a pim contex
#' Model4 <- pim(PO(L(Height),R(Height)) ~ I(R(Age) - L(Age)) + I(R(Sex) - L(Sex)),
#' data=FEVData,
#' estim = "estimator.BB")
#' # is the same as
#' Model5 <- pim(Height ~ Age + Sex, data = FEVData, estim = "estimator.BB")
#' summary(Model4)
#' summary(Model5)
#' }
#' @export
pim <- function(formula,
                data,
                link = c("logit","probit","identity"),
                compare = if(model =='marginal') "all" else "unique",
                model = c("difference","marginal",
                          "regular","customized"),
                na.action = getOption("na.action"),
                weights=NULL,
                keep.data = FALSE,
                ...
                ){

  # Check the arguments
  model <- match.arg(model)
  if(is.character(compare)){
    if(!compare %in% c("unique","all"))
      stop("compare should have the value 'unique' or 'all' in case it's a character value.")
  }
  nodata <- missing(data)
  link <- match.arg(link)

  if(is.null(na.action)) na.action <- "na.fail"
  if(!is.character(na.action))
    na.action <- deparse(substitute(na.action))

  # Check formula and extract info
  f.terms <- terms(formula, simplify=TRUE)

  vars <- all.vars(formula)

  if(nodata){
    if(!all(pres <- vars %in% ls(parent.frame())) )
      stop(paste("Following variables can't be found:",
                 .lpaste(vars[!pres]))
           )
  } else {
    if(!all(pres <- vars %in% names(data)))
      stop(paste("Following variables can't be found:",
                 .lpaste(vars[!pres]))
           )

  }

  # Create the pim environment (similar to model frame)

  penv <- if(nodata)
    new.pim.env(parent.frame(),compare = compare, vars=vars,
                env=parent.frame())
  else
    new.pim.env(data, compare = compare, vars=vars,
                env=parent.frame())

  ff <- new.pim.formula(formula, penv)

  x <- model.matrix(ff, na.action = na.action,
                    model = model)
  y <- eval(lhs(ff), envir=penv)

  res <- pim.fit(x, y, link, weights = weights,
                 penv = as.environment(penv@poset), ...)
  # as.environment will only pass the environment of the penv to avoid
  # copying the whole thing. makes it easier to get the poset out

  names(res$coef) <- colnames(x)

  if(!keep.data){
    x <- matrix(nrow=0,ncol=0)
    y <- numeric(0)
  }

  new.pim(
    formula = ff,
    coef = res$coef,
    vcov = res$vcov,
    fitted = res$fitted,
    penv = penv,
    link = link,
    estimators=res$estim,
    model.matrix = x,
    na.action = na.action,
    response = y,
    keep.data = keep.data,
    model = model)
}
