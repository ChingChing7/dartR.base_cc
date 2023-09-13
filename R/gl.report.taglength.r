#' @name gl.report.taglength
#' @title Reports summary of sequence tag length across loci
#' @family matched report
#' 
#' @description
#' SNP datasets generated by DArT typically have sequence tag lengths ranging
#' from 20 to 69 base pairs. This function reports summary statistics of the tag
#'  lengths.
#' @param x Name of the genlight object containing the SNP [required].
#' @param plot.display If TRUE, histograms of base composition are displayed in the plot window
#' [default TRUE].
#' @param plot.theme Theme for the plot. See Details for options
#' [default theme_dartR()].
#' @param plot.colors List of two color names for the borders and fill of the
#'  plots [default c("#2171B5", "#6BAED6")].
#' @param plot.dir Directory in which to save files [default = working directory]
#' @param plot.file Name for the RDS binary file to save (base name only, exclude extension) [default NULL]
#' @param verbose Verbosity: 0, silent or fatal errors; 1, begin and end; 2,
#' progress log; 3, progress and results summary; 5, full report
#' [default 2, unless specified using gl.set.verbosity]

#' @details The function \code{\link{gl.filter.taglength}} will filter out the
#'  loci with a tag length below a specified threshold.

#' Quantiles are partitions of a finite set of values into q subsets of (nearly)
#' equal sizes. In this function q = 20. Quantiles are useful measures because
#' they are less susceptible to long-tailed distributions and outliers.

#'\strong{ Function's output }

#'  The minimum, maximum, mean and a tabulation of tag length quantiles against
#'  thresholds are provided. Output also includes a boxplot and a
#'  histogram to guide in the selection of a threshold for filtering on tag
#'  length.
#'   If a plot.file is given, the ggplot arising from this function is saved as an "RDS" 
#' binary file using saveRDS(); can be reloaded with readRDS(). A file name must be 
#' specified for the plot to be saved.

#'  If a plot directory (plot.dir) is specified, the ggplot binary is saved to that
#'  directory; otherwise to the tempdir(). 
#'  Examples of other themes that can be used can be consulted in \itemize{
#'  \item \url{https://ggplot2.tidyverse.org/reference/ggtheme.html} and \item
#'  \url{https://yutannihilation.github.io/allYourFigureAreBelongToUs/ggthemes/}
#'  }

#' @author Custodian: Arthur Georges -- Post to
#' \url{https://groups.google.com/d/forum/dartr}
#' 
#' @examples
#' out <- gl.report.taglength(testset.gl)

#' 
#' @seealso \code{\link{gl.filter.taglength}}
#' @import patchwork
#' @export
#' @return Returns unaltered genlight object

gl.report.taglength <- function(x,
                                plot.display=TRUE,
                                plot.theme = theme_dartR(),
                                plot.colors = NULL,
                                plot.file=NULL,
                                plot.dir=NULL,
                                verbose = NULL) {
  # SET VERBOSITY
    verbose <- gl.check.verbosity(verbose)
    
  # SET WORKING DIRECTORY
    plot.dir <- gl.check.wd(plot.dir,verbose=0)
	
	# SET COLOURS
    if(is.null(plot.colors)){
      plot.colors <- gl.select.colors(library="brewer",palette="Blues",select=c(7,5), verbose=0)
    }
    
    # FLAG SCRIPT START
    funname <- match.call()[[1]]
    utils.flag.start(func = funname,
                     build = "v.2023.2",
                     verbose = verbose)
    
    # CHECK DATATYPE
    datatype <- utils.check.datatype(x, verbose = verbose)
    
    # FUNCTION SPECIFIC ERROR CHECKING
    
    if (length(x@other$loc.metrics$TrimmedSequence) != nLoc(x)) {
        stop(
            error(
                "Fatal Error: Data must include Trimmed Sequences for each loci 
                in a column called 'TrimmedSequence' in the @other$loc.metrics
                slot.\n"
            )
        )
    }
    
    # DO THE JOB
    
    tags <- x@other$loc.metrics$TrimmedSequence
    nchar.tags <- nchar(as.character(tags))
    
    plot.tags <- data.frame(nchar.tags)
    colnames(plot.tags) <- "tags"
    
    # Boxplot
    p1 <-
        ggplot(plot.tags, aes(y = tags)) + 
      geom_boxplot(color = plot.colors[1], fill = plot.colors[2]) + 
      coord_flip() + plot.theme + xlim(range = c(-1,1)) + 
      ylim(0, 100) + ylab(" ") + 
      theme(axis.text.y = element_blank(), axis.ticks.y = element_blank()) + 
      ggtitle("SNP data - Tag Length")
    
    # Histogram
    p2 <-
        ggplot(plot.tags, aes(x = tags)) + 
      geom_histogram(bins = 50,color = plot.colors[1], fill = plot.colors[2]) + 
      coord_cartesian(xlim = c(0,100)) + 
      xlab("Tag Length") + 
      ylab("Count") + 
      plot.theme
    
    # Print out some statistics
    stats <- summary(nchar.tags)
    cat("  Reporting Tag Length\n")
    cat("  No. of loci =", nLoc(x), "\n")
    cat("  No. of individuals =", nInd(x), "\n")
    cat("    Minimum      : ", stats[1], "\n")
    cat("    1st quantile : ", stats[2], "\n")
    cat("    Median       : ", stats[3], "\n")
    cat("    Mean         : ", stats[4], "\n")
    cat("    3r quantile  : ", stats[5], "\n")
    cat("    Maximum      : ", stats[6], "\n")
    cat("    Missing Rate Overall: ", round(sum(is.na(as.matrix(
        x
    ))) / (nLoc(x) * nInd(x)), 2), "\n\n")
    
    # Determine the loss of loci for a given threshold using quantiles
    quantile_res <-
        quantile(nchar.tags, probs = seq(0, 1, 1 / 20),type=1)
    retained <- unlist(lapply(quantile_res, function(y) {
        res <- length(nchar.tags[nchar.tags >= y])
    }))
    pc.retained <- round(retained * 100 / nLoc(x), 1)
    filtered <- nLoc(x) - retained
    pc.filtered <- 100 - pc.retained
    df <-
        data.frame(as.numeric(sub("%", "", names(quantile_res))),
                   quantile_res,
                   retained,
                   pc.retained,
                   filtered,
                   pc.filtered)
    colnames(df) <-
        c("Quantile",
          "Threshold",
          "Retained",
          "Percent",
          "Filtered",
          "Percent")
    df <- df[order(-df$Quantile), ]
    df$Quantile <- paste0(df$Quantile, "%")
    rownames(df) <- NULL
    
    # PRINTING OUTPUTS
    if (plot.display) {
        # using package patchwork
        p3 <- (p1 / p2) + plot_layout(heights = c(1, 4))
        print(p3)
    }
    print(df)
    
    if(!is.null(plot.file)){
      tmp <- utils.plot.save(p3,
                             dir=plot.dir,
                             file=plot.file,
                             verbose=verbose)
    }
    
    # FLAG SCRIPT END
    
    if (verbose >= 1) {
        cat(report("Completed:", funname, "\n"))
    }
    
    # RETURN
    invisible(x)
    
}
