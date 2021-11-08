# Author: Julien Diot juliendiot@ut-biomet.org
# 2020 The University of Tokyo
#
# Description:
# data vizualization functions




#' Title
#'
#' @param geno
#' @param weight
#' @param split_ind
#' @param parents
#'
#' @author Sakurai Kengo, Diot Julien
#' @return plotly
SeePlot <- function(predData, selected) {

  # make data.frame
  dat <- predData

  if (length(selected) > 0) {
    annot <- list(
      x = dat[selected, "Trait1"],
      y = dat[selected, "Trait2"],
      text = dat[selected, "ind"],
      xref = "x",
      yref = "y",
      showarrow = TRUE,
      arrowhead = 7,
      ax = 20,
      ay = -40
    )
  } else {
    annot <- list()
  }

  # plot the individuals
  plt <- plot_ly(type = "scatter",
                 mode = "markers",
                 data = dat,

                 x = ~Trait1,
                 y = ~Trait2,
                 color = ~Trait3,

                 hoverinfo = "text",
                 opacity = 0.7,
                 text = apply(dat, 1, function(l) {
                                           paste(names(l), ":", l, collapse = "\n")
                                         })) %>%
    plotly::layout(xaxis = list(title = list(text = "Trait1")),
                   yaxis = list(title = list(text = "Trait2")),
                   annotations = annot)
  plt
}



#' Predict genotypic values from marker effects (genomic prediction)
#'
#' @param geno
#' @param weight
#' @param includeIntercept
#'
#' @author Hamazaki Kosuke
predGenVal <- function (geno, weight,
                        includeIntercept = TRUE) {
  if (includeIntercept) {
    X <- cbind(Intercept = rep(1, nrow(geno)),
               as.matrix(geno) - 1)      # マーカー遺伝子型を{-1, 0, 1}のスコアリングに変更し、切片に対応する部分を追加
    beta <- as.matrix(weight)     # weightの型を data.frame -> matrix に変換
  } else {
    X <- as.matrix(geno) - 1  # マーカー遺伝子型を{-1, 0, 1}のスコアリングに変更
    beta <- as.matrix(weight[-1, ])     # weightの型を data.frame -> matrix に変換
  }
  X <- X[, rownames(beta)]     # マーカー遺伝子型のマーカーの順番をマーカー効果のマーカーの順番に合わせる
  YPred <- X %*% beta     # 上で記した計算式を実行して遺伝子型値を推定
  colnames(YPred) <- paste0("trait", 1:3)

  return(YPred)
}
