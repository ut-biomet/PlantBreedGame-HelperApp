# Author: Julien Diot juliendiot@ut-biomet.org
# 2020 The University of Tokyo
#
# Description:
# parents selection's functions

#' Extract top n individuals from vector v
#'
#' @param v
#' @param n
#' @param decreasing
#'
extractTopN <- function (v, n, decreasing = TRUE) {      # vというベクトルの上からn系統を取ってくる関数を定義
  sort(v, decreasing = decreasing)[1:n]
}

#' Select candidates for parentCands from predicted values
#'
#' @param YPred
#' @param tre
#' @param traitNo
#' @param nCluster
#' @param topCluster
#' @param nTopEach
#' @param nMaxDisease
#' @param nTop
#'
#' @author Hamazaki Kosuke
selectParentCands <- function(YPred, tre, traitNo = 1:2,
                               nCluster = 10, topCluster = 10,
                               nTopEach = 3, nMaxDisease = 2,
                               nTop = NULL) {


  rownames(YPred) <- YPred$ind
  gr <- cutree(tre, nCluster) # nClusterに分割

  YPredAdjusted <- apply(X = YPred[, c("Trait1", "Trait2", "Trait3","Trait1 x Trait2")],
                         MARGIN = 2,
                         FUN = function(y) {
                           y <- as.numeric(y)
                           if (any(y < 0)) {
                             y2 <- y - min(y)
                           } else {
                             y2 <- y
                           }
                           return(y2)
                         })  # 最低が0以上になるように調整
  rownames(YPredAdjusted) <- rownames(YPred)

  # yProd <- apply(X = YPredAdjusted[, traitNo, drop = FALSE],
  #                MARGIN = 1, FUN = prod)  # 形質1×形質2を計算
  yProd <- YPredAdjusted[, traitNo, drop = FALSE]

  # YPredSplit <- split(yProd, gr)      # 予測値を各グループごとに分割（list形式）
  YindSplit <- split(rownames(YPred), gr, sep = "TTT")
  YPredSplit <- lapply(YindSplit, function(l){
    out <- yProd[l,]
    names(out) <- l
    out
  })

  YPredTopN <- lapply(YPredSplit, extractTopN,
                      nTopEach, decreasing = T)    # 各グループに対して、上で定めた関数を作用させている

  if (topCluster > nCluster) {
    topCluster <- nCluster
    message(paste0("topCluster will be set as ",
                   nCluster, "!"))
  }   # topClusterはnCluster以下になるように設定

  YPredTopNMean <- sapply(YPredTopN, mean)  # 各クラスタの上位n系統の平均値を算出
  YPredTopNMeanOrdered <- order(YPredTopNMean, decreasing = TRUE) # 上位n系統の平均値が大きい順にクラスタを並び替え
  YPredTopNMeanOrderedTops <- YPredTopNMeanOrdered[1:topCluster] # 上位topCluster個のクラスタ番号

  YPredTopN2 <- YPredTopN[YPredTopNMeanOrderedTops] # 上位topCluster個のクラスタの予測値リスト
  YPredTopN2Vec <- unlist(YPredTopN2, use.names = FALSE)  # リストをベクトル化
  parentCands0 <- c(sapply(YPredTopN2, names))  # 親の候補となりうる系統名
  names(YPredTopN2Vec) <- parentCands0

  YPredTopN2VecSorted <- sort(YPredTopN2Vec, decreasing = TRUE)  # 大きい順に並び替え
  parentCandsSorted <- parentCands0[order(YPredTopN2Vec, decreasing = TRUE)] # 親候補の系統名も並び替え

  disease <- as.numeric(as.character(YPred[parentCandsSorted, "Trait3"])) < 0  # 親候補で耐病性をもたない系統

  if (nMaxDisease > 0 & sum(disease) > 0) {
    parentCandsDisease <- (parentCandsSorted[disease])[1:min(sum(disease), nMaxDisease)]
  } else {
    parentCandsDisease <- NULL
  }   # 親候補のうち耐病性をもたない系統名

  parentCandsResistance <- parentCandsSorted[!disease]  # 親候補のうち耐病性をもつ系統名
  parentCands <- c(parentCandsDisease, parentCandsResistance)  #親候補の系統名

  YPredTopN2VecFinal <- YPredTopN2VecSorted[parentCands]
  YPredTopN2VecFinalSorted <- sort(YPredTopN2VecSorted, decreasing = TRUE)  # 親候補の予測値を大きい順に並び替え


  if (!is.null(nTop)) {
    if (nTop <= length(parentCands)) {
      parentCands <- parentCands[order(YPredTopN2VecFinal, decreasing = TRUE)[1:nTop]]
    }
  }  # nTop が設定されている場合は上位 nTop 系統を親候補に設定


  return(parentCands)
}












#' Mate pairs to generate next generation
#'
#' @param parentCands
#' @param YPred
#' @param d
#' @param targetPop
#' @param mateMethod
#' @param includeSelfing
#' @param removeDxD
#' @param allocateMethod
#' @param nTotal
#' @param traitNo
#' @param h
#'
#' @author Hamazaki Kosuke
matePairs <- function (parentCands, YPred = NULL, d = NULL,
                       targetPop, mateMethod = "round-robin",
                       includeSelfing = FALSE, removeDxD = TRUE,
                       allocateMethod = "equal", nTotal = 300,
                       traitNo = 1:2, h = 0.1) {
  # browser()
  ### 交配親の組の決定

  if (mateMethod == "autofecundation") {
    crosses <- data.frame(parent1 = parentCands,
                          parent2 = parentCands)
    removeDxD <- FALSE
  } else if (mateMethod == "round-robin") {
    parentCandsRand <- sample(parentCands)   # 親候補を無作為に並び替え
    crosses <- data.frame(parent1 = parentCandsRand,
                          parent2 = c(parentCandsRand[-1],
                                      parentCandsRand[1])) # round-robin
  } else if (mateMethod == "max-distance") {
    if (is.null(d)) {
      stop(paste0("Please set genetic distance between individuals by `d` ! \n",
                  "\t Or please set `mateMethod = 'round-robin'` or `mateMethod = 'allCombination'` !"))
    } # d が NULL ならエラー

    distMat <- as.matrix(d)
    parentCandsNow <- parentCands
    distMatCandNow <- distMat[parentCandsNow, parentCandsNow] # 親候補の距離行列

    ### 距離が一番遠いもの同士を交配
    parentPairs <- c()

    while (length(parentCandsNow) > 1) {
      whichMaxDist <- which(distMatCandNow == max(distMatCandNow),
                            arr.ind = TRUE)[1, ] # 一番遠い距離
      parentPair <- parentCandsNow[whichMaxDist] #　遺伝的距離が一番遠い親候補の系統名
      parentPairs <- rbind(parentPairs, parentPair)
      parentCandsNow <- parentCandsNow[!(parentCandsNow %in% parentPairs)] # 今決めた交配親の組は元の親候補の系統名のベクトルから削除
      distMatCandNow <- distMat[parentCandsNow, parentCandsNow]
    }

    if (length(parentCandsNow) == 1) {
      distMatCandNow <- distMat[parentCandsNow, parentCands]
      whichMaxDist <- which(distMatCandNow == max(distMatCandNow),
                            arr.ind = TRUE)
      parentPair <- c(parentCandsNow, parentCands[whichMaxDist])
      parentPairs <- rbind(parentPairs, parentPair)
    }
    crosses <- parentPairs
  } else if (mateMethod == "all-combination") {
    crosses <- t(combn(x = parentCands, m = 2)) # 全ての組合せを書き出し
    if (includeSelfing) {
      crosses <- rbind(crosses,
                       cbind(parentCands,
                             parentCands))
    } # 自殖させる場合は includeSelfing = TRUE で追加
  }

  rownames(crosses) <- 1:nrow(crosses)
  colnames(crosses) <- paste0("parent", 1:2)

  if (removeDxD) {
    row.names(YPred) <- YPred$ind
    diseaseCheck <- cbind(as.numeric(as.character(YPred[crosses[, 1], "Trait3"])) < 0,
                          as.numeric(as.character(YPred[crosses[, 2], "Trait3"])) < 0)
    crosses <- crosses[!apply(diseaseCheck, 1, all), ]
    rownames(crosses) <- 1:nrow(crosses)
  } # removeDxD = TRUE なら、親が両方耐病性をもたないペアは除外



  ### 各組合せに対する次世代個体数の割り振り
  if (allocateMethod == "equal") {  # 等しく割り当てる場合
    nPairs <- nrow(crosses)
    nProgenyPerPair <- nTotal %/% nPairs
    nProgenies <- rep(nProgenyPerPair, nPairs)
    nResids <- nTotal %% nPairs

    if (nResids > 0) {
      nProgenies[1:nResids] <- nProgenies[1:nResids] + 1
    }  # 余りがある場合は順番に1個体ずつ加える
  } else if (allocateMethod == "weighted") {  # 形質1×形質2の予測値で重み付け
    if (is.null(YPred)) {
      stop(paste0("Please set predicted values by `YPred` ! \n",
                  "\t Or please set `allocateMethod == 'weighted'` !"))
    } #YPred が NULL ならエラー
    rownames(YPred) <- YPred$ind
    YPredAdjusted <- apply(X = YPred[, c("Trait1", "Trait2", "Trait3","Trait1 x Trait2")],
                           MARGIN = 2,
                           FUN = function(y) {
                             y <- as.numeric(y)
                             if (any(y < 0)) {
                               y2 <- (y - min(y))/sd(y)
                             } else {
                               y2 <- y/sd(y)
                             }
                             return(y2)
                           })  # 最低が0以上になるように調整
    rownames(YPredAdjusted) <- rownames(YPred)

    # yProd <- apply(X = YPredAdjusted[, traitNo, drop = FALSE],
    #                MARGIN = 1, FUN = prod)  # 形質1×形質2を計算
    yProd <- as.numeric(YPredAdjusted[, traitNo, drop = FALSE])
    names(yProd) <- YPred$ind

    yProdEachPair <- (yProd[crosses[, 1]] + yProd[crosses[, 2]]) / 2  # 各ペアの目標値を親の平均値で算出
    ######
    ######
    ######
    ###### problem when h * yProdEachPair is too high
    ###### exp(h * yProdEachPair) return Infs
    ######
    ######
    ######
    # nProgenies0 <- floor(nTotal * exp(h * yProdEachPair) / sum(exp(h * yProdEachPair))) # 各ペアの目標値で重み付けた次世代個体数の算出（ソフトマックス関数の利用）
    # browser()
    nProgenies0 <- floor(nTotal * pmin(exp(h * yProdEachPair), 10^9) / sum( pmin(exp(h * yProdEachPair), 10^9))) # julien. limit exp(h * yProdEachPair) at 10^9
    crosseSorted <- crosses[order(yProdEachPair, decreasing = TRUE), ]
    nProgenies <- nProgenies0[order(yProdEachPair, decreasing = TRUE)]

    nResids <- nTotal - sum(nProgenies0)
    # browser()
    if (nResids > 0) {
      nProgenies[1:nResids] <- nProgenies[1:nResids] + 1
    } # 余りがある場合は目標値が大きいものから順番に1個体ずつ加える
  }


  if (targetPop == "F0" ) {
    orderForm <- data.frame(crosses,
                            n_progeny = 1)
  } else {
    orderForm <- data.frame(crosses,
                            n_progeny = nProgenies)
  }



  # } else { # 今の集団がF0なら、F1とF2用にそれぞれリクエストファイルを作る
  #   orderFormForF1 <- data.frame(crosses,
  #                                n_progeny = 1)
  #
  #   nF1 <- nrow(crosses)
  #   namesF1 <- paste0("F1_", sprintf(fmt = paste0("%0", floor(log10(max(1:nF1))) + 1, "i"), 1:nF1),
  #                     ".1")
  #   orderFormForF2 <- data.frame(parent1 = namesF1,
  #                                parent2 = namesF1,
  #                                n_progeny = nProgenies)
  #
  #   orderForm <- list(F1 = orderFormForF1,
  #                     F2 = orderFormForF2)
  #   orderForm <- orderFormForF1
  #   # return(orderForm)
  # }

  orderForm
}
