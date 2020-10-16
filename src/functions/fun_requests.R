# Author: Julien Diot juliendiot@ut-biomet.org
# 2020 The University of Tokyo
#
# Description:
# requestManagment functions



#' Check request
#'
#' @param req data.frame "parent1", "parent2", "nChild"
#' @param prefix F1, F2, ...
#'
#' @return bool
checkRequest <- function(req,
                         prefix){

  # check if file uploaded
  if (is.null(req)) {
    return("No file uploaded.")
  }

  # check columns values
  if (ncol(req)!=3) {
    nCol <- ncol(req)
    print(nCol) # show wrong lines
    msg <- paste("Error: Wrong number of columns.\nYour file have",
                 nCol, "columns instead of 3.\nPlease check your separator.")
    alert(msg)
    return(msg)
  }


  # check NA values
  if (any(is.na(req))) {
    naLines <- which(rowSums(is.na(req)) > 0)
    print(req[naLines, ]) # show wrong lines
    msg <- paste("Error: Empty cells detected at lines: ",
                 paste(naLines, collapse = ", "), "\n")
    alert(msg)
    return(msg)
  }

  # check nChild positive
  if (any(req[,3] <= 0)) {
    negLines <- which(req[,3] <= 0)
    print(req[negLines, ]) # show wrong lines
    msg <- paste("Error: Negative values detected at lines: ",
                 paste(negLines, collapse = ", "), "\n")
    alert(msg)
    return(msg)
  }


  # check total number of children
  totChild <- sum(req[,3])
  maxChild <- ifelse(prefix != "F1", MAX_INDS, MAX_F1)
  if (totChild > maxChild) {
    msg <- paste0("Error: Too many children.\n",
                  'For the generation ,"', prefix,
                  '", the maximum number of children is ', maxChild,".\n",
                  'you requested ', totChild, " children.")
    alert(msg)
    return(msg)
  }

  TRUE

}


#' Create Plant Material Request
#'
#' @param req data.frame "parent1", "parent2", "nChild"
#' @param generation generation number
#'
#' @return data.frame "parent1", "parent2", "child"
createPltMatReq <- function(req,
                            prefix) {

  # create main child names
  req$childNames <- sprintf(fmt = paste0(prefix,
                                                 "_%0", floor(log10(nrow(req))) +
                                                   1, "i"),
                                    1:nrow(req))
  # generate output data.frame
  out <- do.call(rbind,
                 apply(req, 1, function(line) {
                   # get number of child
                   nChild <- as.numeric(line[3])
                   # generate child names' suffic
                   suff <- sprintf(fmt = paste0(".%0", floor(log10(nChild)) + 1, "i"),
                                   1:nChild)
                   # return data.frame
                   data.frame(
                     parent1 = rep(line[1], nChild),
                     parent2 = rep(line[2], nChild),
                     child = paste0(line[4], suff)
                   )
                 }))

  row.names(out) <- NULL
  out
}


#' Create Genotyping Request
#'
#' @param pMatReq data.frame from the "createPltMatReq" function
#' @param snpChip type of snp chip. "hd" of "ld"
#'
#' @return data.frame "ind", "task", "details"
createGenoReq <- function(pMatReq, snpChip = "hd"){

  stopifnot(snpChip %in% c("hd", "ld"))


  data.frame(ind = pMatReq$child,
             task = "geno",
             details = snpChip)

}
