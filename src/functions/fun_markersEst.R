# Author: Julien Diot juliendiot@ut-biomet.org
# 2020 The University of Tokyo
#
# Description:
# marker effects estimation's functions



#' #' Estimate genotypic values
#' #'
#' #' @param phenoColl
#' #' @param traitNo
#' #'
#' #' @return
#' #'
#' #' @author Hamazaki Kosuke
#' estGenVal <- function(phenoColl, traitNo = 1:2) {
#'   phenoColl$year <- as.factor(phenoColl$year)
#'   stopifnot(all(traitNo %in% 1:2))
#'
#'   X0 <- model.matrix(~ year + 1, data = phenoColl)   # 年次の違い
#'   X0 <- cbind(X0, trait3 = phenoColl$trait3)         # 耐病性の有無
#'   Z <- model.matrix(~ ind - 1, data = phenoColl)     # 表現型と系統の対応づけ
#'   K <- diag(x = 1, nrow = ncol(Z), ncol = ncol(Z))   # 系統の関係を表す行列（同じ系統なら1、違う系統なら0）
#'   rownames(K) <- colnames(K) <- colnames(Z)
#'   ZETA <- list(A = list(Z = Z, K = K))
#'
#'   ### 形質1（収量）・形質2（アルカイド濃度）の遺伝子型値の推定
#'   resMMs <- apply(X = phenoColl[, 4 + traitNo, drop = FALSE], MARGIN = 2,
#'                   FUN = function (y) {
#'                     names(y) <- rownames(phenoColl)
#'                     res <- RAINBOWR::EMM.cpp(y = y, ZETA = ZETA, X = X0, REML = TRUE)
#'
#'                     return(res)
#'                   })
#'   Y <- sapply(resMMs, function (res) {
#'     tBlup <- res$u  # 遺伝子型値
#'     names(tBlup) <- substring(colnames(Z), 4, 11)
#'
#'     return(tBlup)
#'   })
#'
#'   tIntercepts <- sapply(resMMs, function (res) {
#'     return(res$beta[1])  # 切片
#'   })
#'
#'   return(list(Y = Y, tIntercepts = tIntercepts))
#' }

estGenVal <- function (phenoColl) {
  phenoColl$year <- as.factor(phenoColl$year)

  ### 形質1（収量）の遺伝子型値の推定
  res1 <- lmer(formula = trait1 ~ (1 | ind) + year + trait3, data = phenoColl, REML = TRUE)
  t1Blup <- ranef(res1)$ind[, 1]  # 遺伝子型値
  t1Intercept <- fixef(res1)[1]  # 切片

  ### 形質2（有効成分）の遺伝子型値の推定
  res2 <- lmer(formula = trait2 ~ (1 | ind) + year + trait3, data = phenoColl, REML = TRUE)
  t2Blup <- ranef(res2)$ind[, 1]  # 遺伝子型値
  t2Intercept <- fixef(res2)[1]  # 切片

  tIntercepts <- c(t1Intercept, t2Intercept)

  Y <- cbind(t1Blup, t2Blup)
  rownames(Y) <- unique(phenoColl$ind)
  colnames(Y) <- names(tIntercepts) <- paste0("trait", 1:2)

  return(list(Y = Y, tIntercepts = tIntercepts))
}

#' Convert Trait 3 (resistance)
#'
#' @param phenoColl
#'
#' @return
#'
#' @author Hamazaki Kosuke
convResistance <- function (phenoColl) {
  phenoPatho <- phenoColl[phenoColl$pathogen == TRUE,
                          c("ind", "year", "trait3")]
  phenoPatho$year <- as.factor(as.character(phenoPatho$year))
  phenoPatho$ind <- as.factor(as.character(phenoPatho$ind))
  dis <- tapply(phenoPatho$trait3, phenoPatho$ind, sum)      # 各系統が病害ありだった回数
  non <- tapply(1 - phenoPatho$trait3, phenoPatho$ind, sum)  # 各系統が病害なしだった回数
  resistance <- dis / (dis + non) == 0    # 1度も病害が発生していない系統＝耐病性あり

  y3 <- as.factor(resistance)

  return(y3)
}


#' Reorder marker genotypes by position
#'
#' @param genoColl
#' @param snpCoord
#'
#' @return
#'
#' @author Hamazaki Kosuke
ordMrkGeno <- function (genoColl, snpCoord) {
  snpCoord <- snpCoord[order(snpCoord$chr, snpCoord$pos), ]   # マーカー位置情報を配置順に並び替え
  snpNames <- rownames(snpCoord)
  genoColl <- genoColl[, snpNames]   # マーカー遺伝子型を配置順に並び替え

  X <- as.matrix(genoColl) - 1

  return(X)
}


#' #' Estimate marker effects
#' #'
#' #' @param Y
#' #' @param Xcepts
#' #' @param target
#' #' @param tIntercepts
#' #' @param target
#' #' @param multiTrait
#' #' @param alpha
#' #'
#' #' @return
#' #'
#' #' @author Hamazaki Kosuke
#' estMrkEff <- function (Y, X, tIntercepts, target = "quantitative",
#'                        multiTrait = TRUE, alpha = 0) {
#'
#'   if (target == "quantitative") {
#'     Y <- as.matrix(Y)
#'     nTraits <- ncol(Y)
#'     stopifnot(length(tIntercepts) == nTraits)
#'
#'     lineNamesPheno <- rownames(Y)
#'     lineNamesGeno <- rownames(X)
#'     lineNames <- Reduce(f = intersect, x = list(lineNamesGeno, lineNamesPheno))  # 表現型にもマーカー遺伝子型にも含まれる系統名を抜き出し
#'
#'     X <- X[lineNames, ]   # 一致する系統名でマーカー遺伝子型を並び替え
#'     Y <- Y[lineNames, ]   # 一致する系統名で表現型を並び替え
#'
#'     if (multiTrait) {
#'       stopifnot(length(alpha) == 1)
#'       model <- glmnet::cv.glmnet(x = X, y = Y, family = "mgaussian",
#'                                  alpha = alpha, standardize = FALSE,
#'                                  standardize.response = TRUE)
#'
#'       t1Weight <- as.matrix(coef(model, s = "lambda.min")[[1]])[, 1]
#'       t2Weight <- as.matrix(coef(model, s = "lambda.min")[[2]])[, 1]
#'       t1Weight[1] <- t1Weight[1] + tIntercepts[1]  # マーカー効果の前に切片情報を挿入
#'       t2Weight[1] <- t2Weight[1] + tIntercepts[2]  # マーカー効果の前に切片情報を挿入
#'       tWeights <- data.frame(trait1 = t1Weight, trait2 = t2Weight)
#'     } else {
#'       if (length(alpha) == 1) {
#'         tWeights <- apply(X = Y, MARGIN = 2,
#'                           FUN = function (y) {
#'                             model <- glmnet::cv.glmnet(x = X, y = y, family = "gaussian",
#'                                                        alpha = alpha, standardize = FALSE,
#'                                                        standardize.response = TRUE)
#'                             tWeight <- as.matrix(coef(model, s = "lambda.min"))[, 1]
#'
#'                             return(tWeight)
#'                           })
#'       } else if (length(alpha) == nTraits) {
#'         tWeights <- sapply(X = 1:nTraits,
#'                            FUN = function (traitNo) {
#'                              model <- glmnet::cv.glmnet(x = X, y = Y[, traitNo], family = "gaussian",
#'                                                         alpha = alpha[traitNo], standardize = FALSE,
#'                                                         standardize.response = TRUE)
#'                              tWeight <- as.matrix(coef(model, s = "lambda.min"))[, 1]
#'
#'                              return(tWeight)
#'                            }, simplify = TRUE)
#'       }
#'       tWeights[1, 1] <- tWeights[1, 1] + tIntercepts[1]  # マーカー効果の前に切片情報を挿入
#'       tWeights[1, 2] <- tWeights[1, 2] + tIntercepts[2]  # マーカー効果の前に切片情報を挿入
#'     }
#'
#'     rownames(tWeights) <- c("Intercept", colnames(X))
#'     colnames(tWeights) <- paste0("trait_", 1:nTraits)
#'   } else {
#'     nTraits <- ncol(as.matrix(Y))
#'     stopifnot(nTraits == 1)
#'     tIntercepts <- 0
#'     multiTrait <- FALSE
#'
#'     lineNamesPheno <- names(Y)
#'     lineNamesGeno <- rownames(X)
#'     lineNames <- Reduce(f = intersect, x = list(lineNamesGeno, lineNamesPheno))  # 表現型にもマーカー遺伝子型にも含まれる系統名を抜き出し
#'
#'     X <- X[lineNames, ]   # 一致する系統名でマーカー遺伝子型を並び替え
#'     Y <- Y[lineNames]   # 一致する系統名で表現型を並び替え
#'
#'     model <- glmnet::cv.glmnet(x = X, y = Y, family = "binomial",
#'                                alpha = alpha, standardize = FALSE)
#'     tWeights <- c(Intercept = 0, as.matrix(coef(model, s = "lambda.min"))[-1, 1])  # マーカー効果の前に切片情報を挿入
#'     names(tWeights) <- c("Intercept", colnames(X))
#'   }
#'
#'   return(tWeights)
#' }
#'





### Estimate marker effects
estMrkEff <- function (Y, X, tIntercepts, target = "quantitative",
                       method = "GBLUP", multiTrait = TRUE, alpha = 0) {

  if (target == "quantitative") {
    Y <- as.matrix(Y)
    nTraits <- ncol(Y)
    stopifnot(length(tIntercepts) == nTraits)

    lineNamesPheno <- rownames(Y)
    lineNamesGeno <- rownames(X)
    lineNames <- Reduce(f = intersect, x = list(lineNamesGeno, lineNamesPheno))  # 表現型にもマーカー遺伝子型にも含まれる系統名を抜き出し
    X <- X[lineNames, ]   # 一致する系統名でマーカー遺伝子型を並び替え
    Y <- Y[lineNames, ]   # 一致する系統名で表現型を並び替え

    if (method == "GBLUP") {
      multiTrait <- FALSE

      K <- tcrossprod(X) / ncol(X)  # 系統間の類似度を示すゲノム関係行列
      KInv <- solve(K)              # 関係行列の逆行列（あとで使用）

      tWeights <- sapply(X = 1:nTraits,
                         FUN = function (traitNo) {
                           model <- rrBLUP::mixed.solve(y = Y[, traitNo], X = NULL,
                                                        Z = diag(nrow(K)), K = K)
                           yFitted <- model$u   # 予測された遺伝子型値
                           yIntercept <- model$beta  # 切片情報
                           tWeight <- (crossprod(X / ncol(X), KInv) %*% yFitted)[, 1]  # マーカー効果の算出
                           tWeight <- c(Intercept = yIntercept, tWeight)

                           return(tWeight)
                         }, simplify = TRUE)

      tWeights[1, 1] <- tWeights[1, 1] + tIntercepts[1]  # マーカー効果の前に切片情報を挿入
      tWeights[1, 2] <- tWeights[1, 2] + tIntercepts[2]  # マーカー効果の前に切片情報を挿入
    } else {
      if (multiTrait) {
        stopifnot(length(alpha) == 1)
        model <- glmnet::cv.glmnet(x = X, y = Y, family = "mgaussian",
                                   alpha = alpha, standardize = FALSE,
                                   standardize.response = TRUE)

        t1Weight <- as.matrix(coef(model, s = "lambda.min")[[1]])[, 1]
        t2Weight <- as.matrix(coef(model, s = "lambda.min")[[2]])[, 1]
        t1Weight[1] <- t1Weight[1] + tIntercepts[1]  # マーカー効果の前に切片情報を挿入
        t2Weight[1] <- t2Weight[1] + tIntercepts[2]  # マーカー効果の前に切片情報を挿入
        tWeights <- data.frame(trait1 = t1Weight, trait2 = t2Weight)
      } else {
        if (length(alpha) == 1) {
          tWeights <- apply(X = Y, MARGIN = 2,
                            FUN = function (y) {
                              model <- glmnet::cv.glmnet(x = X, y = y, family = "gaussian",
                                                         alpha = alpha, standardize = FALSE,
                                                         standardize.response = TRUE)
                              tWeight <- as.matrix(coef(model, s = "lambda.min"))[, 1]

                              return(tWeight)
                            })
        } else if (length(alpha) == nTraits) {
          tWeights <- sapply(X = 1:nTraits,
                             FUN = function (traitNo) {
                               model <- glmnet::cv.glmnet(x = X, y = Y[, traitNo], family = "gaussian",
                                                          alpha = alpha[traitNo], standardize = FALSE,
                                                          standardize.response = TRUE)
                               tWeight <- as.matrix(coef(model, s = "lambda.min"))[, 1]

                               return(tWeight)
                             }, simplify = TRUE)
        }
        tWeights[1, 1] <- tWeights[1, 1] + tIntercepts[1]  # マーカー効果の前に切片情報を挿入
        tWeights[1, 2] <- tWeights[1, 2] + tIntercepts[2]  # マーカー効果の前に切片情報を挿入
      }
    }

    rownames(tWeights) <- c("Intercept", colnames(X))
    colnames(tWeights) <- paste0("trait_", 1:nTraits)
  } else {
    nTraits <- ncol(as.matrix(Y))
    stopifnot(nTraits == 1)
    tIntercepts <- 0
    multiTrait <- FALSE

    lineNamesPheno <- names(Y)
    lineNamesGeno <- rownames(X)
    lineNames <- Reduce(f = intersect, x = list(lineNamesGeno, lineNamesPheno))  # 表現型にもマーカー遺伝子型にも含まれる系統名を抜き出し

    X <- X[lineNames, ]   # 一致する系統名でマーカー遺伝子型を並び替え
    Y <- Y[lineNames]   # 一致する系統名で表現型を並び替え

    model <- glmnet::cv.glmnet(x = X, y = Y, family = "binomial",
                               alpha = alpha, standardize = FALSE)
    tWeights <- c(Intercept = 0, as.matrix(coef(model, s = "lambda.min"))[-1, 1])  # マーカー効果の前に切片情報を挿入
    names(tWeights) <- c("Intercept", colnames(X))
  }

  return(tWeights)
}
