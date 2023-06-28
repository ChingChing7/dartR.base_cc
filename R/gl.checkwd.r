#' Checks the global working directory

#' The working directory can be set in one of two ways -- (a) explicitly by the user by
#' passing a value using the parameter plot.dir in a function, or (b) by setting
#' the working directory globally as part of the r environment (gl.setwd). The default is in acccordance to CRAN set to tempdir().

#' @param wd path to the working directory [default: tempdir()].
#' @return the working directory
#' @examples 
#' gl.checkwd()
#' @author Custodian: Bernd Gruber (Post to
#' \url{https://groups.google.com/d/forum/dartr})
#' @export
#' @author Bernd Gruber (Post to \url{https://groups.google.com/d/forum/dartr})

gl.checkwd <- function(wd = NULL) {
    # SET wd or GET it from global
    if (is.null(wd)) {
        if (is.null(options()$dartR_wd)) {
             wd <- tempdir()
        } else {
            wd <- options()$dartR_wd
        }
    } else {
        if (is.character(wd) & dir.exists(wd)) {
            wd <- wd
        } else {
            cat(
                warn(
                    "Warning: The path to the working directory does not exist! Set to tempdir().\n"
                )
            )
            wd <- tempdir()
        }
    }
    
    return(wd)
    
}
