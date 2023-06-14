#' @name utils.ggplotsave
#' @title A function to save a ggplot file/object to disk. 
#' 
#' @description
#' Uses saveRDS() and ggsave().
#' Additional details ..... options for saving are specified by the parameter
#' type, which can be one of 
#' "RDS", eps", "ps", "tex" (pictex), "pdf", "jpeg", "tiff", "png", 
#' "bmp", "svg" or "wmf" (windows only). If type is specified, Whether or not "RDS", 
#' the function also saves the ggplot object as an RDS binary file using gl.save(); 
#' can be reloaded with gl.load().
#' 
#' @param x Name of the ggplot object.
#' @param type Type of file to save 
#' @param dir Name of the directory to save the file.
#' @param file Name of the file to save the plot to (omit file extension)
#' @param verbose Verbosity: 0, silent or fatal errors; 1, begin and end; 2,
#' progress log; 3, progress and results summary; 5, full report
#'  [default NULL, unless specified using gl.set.verbosity]
#'  @param ... Parameters passed to function \link[ggplot2]{ggsave}, 
#'  such as width and height, when the ggplot is to be saved.
#' 
#' @return NULL

utils.ggplotsave <- function(
  x,
  type=NULL,
  dir=NULL,
  file=NULL,
  verbose=NULL,
  ...
){
  
  errorflag <- 0
  
  # If saving ------------------
  if(!is.null(type)){
    
    typelist <- c("RDS","eps", "ps", "tex", "pdf", "jpeg", "tiff", "png", "bmp", "svg", "wmf")
    if(type=="jpg"){type<-"jpeg"}
    if(type=="tif"){type<-"tiff"}
    if(type=="rds"){type<-"RDS"}
    if(type %in% typelist){
      if(verbose >= 2){cat("Saving a ggplot file",deparse(substitute(x)),"as file type",type,"\n")}
    } else {
      errorflag <- 1
      if(verbose >= 2){cat("Error: type specified as",type,"but not included in list of acceptable types\n")}
      if(verbose >= 2){cat("  Should be one of",typelist,"\n")}
    }
    
    if (!is.ggplot(x) & errorflag==0) {
      if(verbose >= 2){cat("Error:",deparse(substitute(x))," is not a ggplot object, no object saved\n")}
      errorflag <- 1
    }
    
    if(!is.null(dir) & errorflag==0){
      if(!file.exists(dir)){
        if(verbose >= 2){cat("Error: Directory to receive the saved plot file does not exist or is misspecified. Defaulting to working directory\n")}
        dir <- getwd()
      }
    } else {
      dir <- getwd()
    }
    
    if(is.null(file) & errorflag==0){
      if(verbose >= 2){cat("Error: No file name provided for the plot file.\n")}
      file <- NULL
      errorflag <- 1
    }
    
    if(errorflag==0){
      filespec <- file.path(dir, file)
      filespec <- paste0(filespec,".",type)
      if(type=="RDS"){
        if(verbose >= 2){cat("ggplot object will be saved as RDS to",filespec,"using saveRDS()\n")}
        saveRDS(x, filespec)
      } else {
        if(verbose >= 2){cat("ggplot file will be saved as",type,"to",filespec,"using ggsave()\n")}
        if(verbose >= 2){cat("ggplot object will also be saved as RDS binary to",filespec,"using saveRDS()\n")}
        ggsave(x,filename=filespec,device=type)
        saveRDS(x, filespec)
      }
    } 
  } 
  
  if(is.null(type) | errorflag==1){
    cat("    No plot saved\n")
  }

return(NULL)
  
}
