#' @name gl.report.callrate
# HEADER INFORMATION -------------------
#' @title Reports summary of Call Rate for loci or individuals
#' @family matched report
#' 
#' @description
#' SNP datasets generated by DArT have missing values primarily arising from
#' failure to call a SNP because of a mutation at one or both of the restriction
#' enzyme recognition sites. P/A datasets (SilicoDArT) have missing values
#' because it was not possible to call whether a sequence tag was amplified or
#' not. This function tabulates the number of missing values as quantiles.
#' 
#' @param x Name of the genlight object containing the SNP or presence/absence
#'  (SilicoDArT) data [required].
#' @param method Specify the type of report by locus (method='loc') or
#' individual (method='ind') [default 'loc'].
#' @param ind.to.list Number of individuals to list for callrate [default 20]
#' @param plot.display Specify if plot is to be displayed in the graphics window [default TRUE].
#' @param plot.theme User specified theme [default theme_dartR()].
#' @param plot.colors Vector with two color names for the borders and fill
#' [default c("#2171B5", "#6BAED6")].
#' @param plot.dir Directory to save the plot RDS files [default as specified 
#' by the global working directory or tempdir()]
#' @param plot.file Filename (minus extension) for the RDS plot file [Required for plot save]
#' @param bins Number of bins to display in histograms [default 25].
#' @param verbose Verbosity: 0, silent or fatal errors; 1, begin and end; 2,
#' progress log; 3, progress and results summary; 5, full report
#' [default 2, unless specified using gl.set.verbosity].
#' @param ... Parameters passed to function \link[ggplot2]{ggsave}, 
#'  such as width and height, when the ggplot is to be saved.
#' 
#' @details
#' This function expects a genlight object, containing either SNP data or
#' SilicoDArT (=presence/absence data).

#' Callrate is summarized by locus or by individual to allow sensible decisions
#' on thresholds for filtering taking into consideration consequential loss of
#' data. The summary is in the form of a tabulation and plots.
#' 
#' To avoid issues from inadvertent use of this function in an assignment statement,
#' the function returns the genlight object unaltered.

#' Plot themes can be obtained from:
#'  \itemize{
#'  \item \url{https://ggplot2.tidyverse.org/reference/ggtheme.html} and \item
#'  \url{https://yutannihilation.github.io/allYourFigureAreBelongToUs/ggthemes/}
#'  }
#'  
#'  Plot colours can be set with gl.select.colors().
#'  
#'  If plot.file is specified, plots are saved to the directory specified by the user, or the global
#'  default working directory set by gl.set.wd() or to the tempdir().
#' 
#' @author Custodian: Arthur Georges -- Post to
#' \url{https://groups.google.com/d/forum/dartr}
#' 
#' @examples
#'  \donttest{
#' # SNP data
#'   test.gl <- testset.gl[1:20,]
#'   gl.report.callrate(test.gl)
#'   gl.report.callrate(test.gl,method='ind')
#'   gl.report.callrate(test.gl,method='ind',plot.file="test")
#'   gl.report.callrate(test.gl,method='loc',by.pop=TRUE)
#'   gl.report.callrate(test.gl,method='loc',by.pop=TRUE,plot.file="test")
#' # Tag P/A data
#'   test.gs <- testset.gs[1:20,]
#'   gl.report.callrate(test.gs)
#'   gl.report.callrate(test.gs,method='ind')
#'   }
#'   test.gl <- testset.gl[1:20,]
#'   gl.report.callrate(test.gl)
#'   
#' @seealso \code{\link{gl.filter.callrate}}

#' @import patchwork
#' @importFrom stats aggregate
#' @export
#' @return Returns unaltered genlight object
# END HEADER INFORMATION --------------------

gl.report.callrate <- function(x,
                               method = "loc",
                               ind.to.list=20, 
                               plot.display=TRUE,
                               plot.theme = theme_dartR(),
                               plot.colors = NULL,
                               plot.dir=NULL,
                               plot.file=NULL,
                               bins = 50,
                               verbose = NULL,
                               ...) {
  
  # PRELIMINARIES ---------------------------
  # SET VERBOSITY
  verbose <- gl.check.verbosity(verbose)
  
  # SET WORKING DIRECTORY
  plot.dir <- gl.check.wd(plot.dir,verbose=0)
  
  # SET COLOURS
    if(is.null(plot.colors)){
      plot.colors <- gl.select.colors(library="brewer",palette="Blues",select=c(7,5))
    }
  
  # FLAG SCRIPT START
  funname <- match.call()[[1]]
  utils.flag.start(func = funname,
                   build = "v.2023.2",
                   verbose = verbose)
  
  # CHECK DATATYPE
  datatype <- utils.check.datatype(x, verbose = verbose)
  
  # FUNCTION SPECIFIC ERROR CHECKING
  
  # Ib case the call rate is not up to date, recalculate

  x <- utils.recalc.callrate(x, verbose = 0)

  # DO THE JOB -------------------------
  ########### FOR METHOD BASED ON LOCUS ----------------
  if (method == "loc") {
    callrate <- x@other$loc.metrics$CallRate
    
    # Print out some statistics --------------------
    stats <- summary(callrate)
    cat("  Reporting Call Rate by Locus\n")
    cat("  No. of loci =", nLoc(x), "\n")
    cat("  No. of individuals =", nInd(x), "\n")
    cat("    Minimum      : ", stats[1], "\n")
    cat("    1st quartile : ", stats[2], "\n")
    cat("    Median       : ", stats[3], "\n")
    cat("    Mean         : ", stats[4], "\n")
    cat("    3r quartile  : ", stats[5], "\n")
    cat("    Maximum      : ", stats[6], "\n")
    cat("    Missing Rate Overall: ", round(sum(is.na(
      as.matrix(x)
    )) / (nLoc(x) * nInd(x)), 4), "\n\n")
    
    # # Determine the loss of loci for a given threshold
    # quantile_res <-
    #   quantile(callrate, probs = seq(0, 1, 1 / 20),type=1)
    # retained <-
    #   unlist(lapply(quantile_res, function(y) {
    #     res <- length(callrate[callrate >= y])
    #   }))
    # pc.retained <- round(retained * 100 / nLoc(x), 1)
    # filtered <- nLoc(x) - retained
    # pc.filtered <- 100 - pc.retained
    # df <-
    #   data.frame(
    #     as.numeric(sub("%", "", names(
    #       quantile_res
    #     ))),
    #     quantile_res,
    #     retained,
    #     pc.retained,
    #     filtered,
    #     pc.filtered
    #   )
    # colnames(df) <-
    #   c("Quantile",
    #     "Threshold",
    #     "Retained",
    #     "Percent",
    #     "Filtered",
    #     "Percent")
    # df <- df[order(-df$Quantile), ]
    # df$Quantile <- paste0(df$Quantile, "%")
    # rownames(df) <- NULL
    # cat("Refer to this table to decide thresholds for filtering loci\n")
    # print(df[,1:4])
    
    # Prepare the plots ------------------------
    # get title for plots
    if (datatype == "SNP") {
      title1 <- "SNP data - Call Rate by Locus"
    } else {
      title1 <- "Fragment P/A data - Call Rate by Locus"
    }
    
    # Calculate minimum and maximum graph cutoffs for callrate
    min <- min(callrate, na.rm = TRUE)
    min <- trunc(min * 100) / 100
    
    # Boxplot
    p1 <-
      ggplot(data.frame(callrate), aes(y = callrate)) + 
      geom_boxplot(color=plot.colors[1], fill = plot.colors[2]) + 
      coord_flip() +
      plot.theme + 
      xlim(range = c(-1, 1)) + 
      ylim(min, 1) + 
      ylab(" ") + 
      theme(axis.text.y=element_blank(),axis.ticks.y=element_blank()) +
      ggtitle(title1)
    
    # Histogram
    p2 <-
      ggplot(data.frame(callrate), aes(x = callrate)) +
      geom_histogram(bins = bins,color = plot.colors[1],fill = plot.colors[2]) +
      coord_cartesian(xlim = c(min, 1)) +
      xlab("Call rate") +
      ylab("Count") + 
      plot.theme
    
    # using package patchwork
    p3 <- (p1 / p2) + plot_layout(heights = c(1, 4))
    if (plot.display) {print(p3)}
    
    if(!is.null(plot.file)){
      tmp <- utils.plot.save(p3,
                             dir=plot.dir,
                             file=plot.file,
                             verbose=verbose)
    }
      
      # if(nPop(x)>1 & method == "loc" & by.pop == TRUE){
      #   row_plots <- ceiling(nPop(x) / 3)
      #   p4 <- wrap_plots(c_rate_plots)
      #   p4 <- p4 + plot_layout(ncol = 3, nrow = row_plots)
      #   print(p4)
      #   
      #   filename <- paste0(plot.file,"_02")
      #   tmp <- utils.plot.save(p_temp,
      #                          dir=plot.dir,
      #                          file=filename,
      #                          verbose=verbose)
      # }

  #   # plots by population
  #   if(nPop(x)>1 & by.pop==TRUE){
  #     pops <- seppop(x)
  #     
  #     cat("  Reporting Call Rate by population\n")
  #     
  #     c_rate_plots <- lapply(pops, function(z) {
  #       pop_tmp <- utils.recalc.callrate(z, verbose = 0)
  #       c_rate_tmp <- pop_tmp$other$loc.metrics$CallRate
  #       p_temp <-
  #         ggplot(as.data.frame(c_rate_tmp), aes(x = c_rate_tmp)) + 
  #         geom_histogram(bins = bins, color = plot.colors[1],fill = plot.colors[2]) +
  #         xlab("Call rate") + 
  #         ylab("Count") +
  #         coord_cartesian(xlim = c(min, 1)) +
  #         plot.theme + 
  #         ggtitle(paste(popNames(z), "n =", nInd(z)))
  #       
  #       if(verbose >= 3){
  #         cat("   Population:",popNames(pop_tmp),"\n")
  #       cat("   No. of loci =", nLoc(pop_tmp), "\n")
  #       cat("   No. of individuals =", nInd(pop_tmp), "\n")
  #       cat("   Mean Call Rate",mean(pop_tmp$other$loc.metrics$CallRate,na.rm = TRUE) ,
  #           "\n\n")
  #       }
  #       
  #       return(p_temp)
  #     })
  #   }
   }

  ########### FOR METHOD BASED ON INDIVIDUAL -----------------------
  # Calculate the call rate by individual
  if (method == "ind") {
    ind.call.rate <- 1 - rowSums(is.na(as.matrix(x))) / nLoc(x)
    # Print out some statistics
    stats <- summary(ind.call.rate)
    cat(report("\n  Reporting Call Rate by Individual\n"))
    cat("  No. of loci =", nLoc(x), "\n")
    cat("  No. of individuals =", nInd(x), "\n")
    cat("    Minimum      : ", stats[1], "\n")
    cat("    1st quartile : ", stats[2], "\n")
    cat("    Median       : ", stats[3], "\n")
    cat("    Mean         : ", stats[4], "\n")
    cat("    3r quartile  : ", stats[5], "\n")
    cat("    Maximum      : ", stats[6], "\n")
    cat("    Missing Rate Overall: ", round(sum(is.na(as.matrix(x)))/(nLoc(x)*nInd(x)), 4), "\n\n")
    
    # Print out statistics for each population
    sample_sizes <- table(pop(x))
    sample_sizes <- as.matrix(sample_sizes)
    ind.means <- rowSums(!is.na(as.matrix(x)))/nLoc(x)
    means <- aggregate(ind.means ~ pop(x), x, mean)
    means$ind.means <- round(as.numeric(means$ind.means),4)
    means <- cbind(means,sample_sizes)
    names(means) <- c("Population","CallRate","N")
    row.names(means) <- NULL
    cat(report("Listing",nPop(x),"populations and their average CallRates\n"))
    cat(report("  Monitor again after filtering\n"))
    print(means)
    cat("\n")
    
    ind.means <- as.data.frame(ind.means)
    ind.means$Individual <- rownames(ind.means)
    names(ind.means) <- c("CallRate","Individual")
    ind.means <- ind.means[order(ind.means$CallRate), ]
    rownames(ind.means) <- NULL
    ind.means <- ind.means[, c("Individual","CallRate")] 
      cat(report("Listing",ind.to.list,"individuals with the lowest CallRates\n"))
      cat(report("  Use this list to see which individuals will be lost on filtering by individual\n"))
      cat(report("  Set ind.to.list parameter to see more individuals\n"))
    ind.means <- ind.means[1:ind.to.list,]
    print(ind.means)
    cat("\n)")
    
    # # Determine the loss of individuals for a given threshold
    # quantile_res <-
    #   quantile(ind.call.rate, probs = seq(0, 1, 1 / 20),type=1)
    # retained <-
    #   unlist(lapply(quantile_res, function(y) {
    #     res <- length(ind.call.rate[ind.call.rate >= y])
    #   }))
    # pc.retained <- round(retained * 100 / nInd(x), 1)
    # filtered <- nInd(x) - retained
    # pc.filtered <- 100 - pc.retained
    # df <-
    #   data.frame(
    #     as.numeric(sub("%", "", names(
    #       quantile_res
    #     ))),
    #     quantile_res,
    #     retained,
    #     pc.retained,
    #     filtered,
    #     pc.filtered
    #   )
    # colnames(df) <-
    #   c("Quantile",
    #     "Threshold",
    #     "Retained",
    #     "Percent",
    #     "Filtered",
    #     "Percent")
    # df <- df[order(-df$Quantile), ]
    # df$Quantile <- paste0(df$Quantile, "%")
    # rownames(df) <- NULL
    # cat("Refer to this table to decide thresholds for filtering individuals\n")
    # print(df[,1:4])
    
    # Prepare the plots ------------------------
    # get title for plots
    if (datatype == "SNP") {
      title1 <- "SNP data - Call Rate by Individual"
    } else {
      title1 <- "Fragment P/A data - Call Rate by Individual"
    }
    
    # Calculate minimum and maximum graph cutoffs for callrate
    min <- min(ind.call.rate)
    min <- trunc(min * 100) / 100
    
    # Boxplot
    p1 <-
      ggplot(data.frame(ind.call.rate), aes(y = ind.call.rate)) + 
      geom_boxplot(color = plot.colors[1], fill = plot.colors[2]) +
      coord_flip() +
      plot.theme + 
      xlim(range = c(-1, 1)) +
      ylim(min, 1) + 
      ylab(" ") +
      theme(axis.text.y = element_blank(), axis.ticks.y = element_blank()) +
      ggtitle(title1)
    
    # Histogram
    p2 <-
      ggplot(data.frame(ind.call.rate), aes(x = ind.call.rate)) + 
      geom_histogram(bins = bins, color = plot.colors[1],fill = plot.colors[2]) +
      coord_cartesian(xlim = c(min, 1)) + 
      xlab("Call rate") +
      ylab("Count") +
      plot.theme
    
    # using package patchwork
    p3 <- (p1 / p2) + plot_layout(heights = c(1, 4))
    if (plot.display) {print(p3)}
    
    if(!is.null(plot.file)){
      tmp <- utils.plot.save(p3,
                             dir=plot.dir,
                             file=plot.file,
                             verbose=verbose)
    }
      
      # if(nPop(x)>1 & method == "loc" & by.pop == TRUE){
      #   row_plots <- ceiling(nPop(x) / 3)
      #   p4 <- wrap_plots(c_rate_plots)
      #   p4 <- p4 + plot_layout(ncol = 3, nrow = row_plots)
      #   print(p4)
      #   
      #   filename <- paste0(plot.file,"_02")
      #   tmp <- utils.plot.save(p_temp,
      #                          dir=plot.dir,
      #                          file=filename,
      #                          verbose=verbose)
      # }

    
    # # Determine the loss of individuals for a given threshold using quantiles
    # quantile_res <-
    #   quantile(ind.call.rate, probs = seq(0, 1, 1 / 20))
    # retained <- unlist(lapply(quantile_res, function(y) {
    #   res <- length(ind.call.rate[ind.call.rate >= y])
    # }))
    # pc.retained <- round(retained * 100 / nInd(x), 1)
    # filtered <- nInd(x) - retained
    # pc.filtered <- 100 - pc.retained
    # df <-
    #   data.frame(
    #     as.numeric(sub("%", "", names(
    #       quantile_res
    #     ))),
    #     quantile_res,
    #     retained,
    #     pc.retained,
    #     filtered,
    #     pc.filtered
    #   )
    # colnames(df) <-
    #   c("Quantile",
    #     "Threshold",
    #     "Retained",
    #     "Percent",
    #     "Filtered",
    #     "Percent")
    # df <- df[order(-df$Quantile), ]
    # df$Quantile <- paste0(df$Quantile, "%")
    # rownames(df) <- NULL
    # 
    # ind.call.rate_pop <- as.data.frame(cbind(names(ind.call.rate),
    #                                          as.character(pop(x)),
    #                                          ind.call.rate))
    # colnames(ind.call.rate_pop) <- c("ind_name","pop","missing_data")
    # ind.call.rate_pop <- ind.call.rate_pop[order(ind.call.rate_pop$pop,
    #                                              ind.call.rate_pop$missing_data,
    #                                              decreasing = TRUE),]
  }
    

    # # using package patchwork
    # p3 <- (p1 / p2) + plot_layout(heights = c(1, 4))
    # if (plot.display) {print(p3)}
    # 
    # if(!is.null(plot.file)){
    #   if(nPop(x)>1 & method == "loc" & by.pop == TRUE){
    #     filename <- paste0(plot.file,"_01")
    #   } else {
    #     filename <- plot.file
    #   }
    #   tmp <- utils.plot.save(p3,
    #                          dir=plot.dir,
    #                          file=filename,
    #                          verbose=verbose)
    #   
    #   if(nPop(x)>1 & method == "loc" & by.pop == TRUE){
    #     row_plots <- ceiling(nPop(x) / 3)
    #     p4 <- wrap_plots(c_rate_plots)
    #     p4 <- p4 + plot_layout(ncol = 3, nrow = row_plots)
    #     print(p4)
    #     
    #     filename <- paste0(plot.file,"_02")
    #     tmp <- utils.plot.save(p_temp,
    #                            dir=plot.dir,
    #                            file=filename,
    #                            verbose=verbose)
    #   }
    # }

  #print(df)
  # cat("\n\n")
  # if (method == "ind") {
  # print(ind.call.rate_pop, row.names = FALSE)
  # }
  
  # # SAVE INTERMEDIATES TO TEMPDIR
  # 
  # # creating temp file names
  # if (save2tmp) {
  #     if (plot.display) {
  #         temp_plot <- tempfile(pattern = "Plot_")
  #         match_call <-
  #             paste0(names(match.call()),
  #                    "_",
  #                    as.character(match.call()),
  #                    collapse = "_")
  #         # saving to tempdir
  #         saveRDS(list(match_call, p3), file = temp_plot)
  #         
  #         # saving plots per pop
  #         if(nPop(x)>1){
  #         temp_plot_2 <- tempfile(pattern = "Plot_per_pop")
  #         # saving to tempdir
  #         saveRDS(list(match_call, p4), file = temp_plot_2)
  #         }
  #         
  #         if (verbose >= 2) {
  #             cat(report("  Saving the ggplot to session tempfile\n"))
  #         }
  #     }
  #     temp_table <- tempfile(pattern = "Table_")
  #     saveRDS(list(match_call, df), file = temp_table)
  #     if (method == "ind") {
  #     temp_table_2 <- tempfile(pattern = "Table2_")
  #     saveRDS(list(ind.call.rate_pop, df), file = temp_table_2)
  #     }
  #     if (verbose >= 2) {
  #         cat(report("  Saving tabulation to session tempfile\n"))
  #         cat(
  #             report(
  #                 "  NOTE: Retrieve output files from tempdir using 
  #                 gl.list.reports() and gl.print.reports()\n"
  #             )
  #         )
  #     }
  #  }
  
  # FLAG SCRIPT END
  
  if (verbose >= 1) {
    cat(report("Completed:", funname, "\n"))
  }
  
  # RETURN
  invisible(x)
  
}
