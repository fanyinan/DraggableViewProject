//
//  DraggableView.swift
//  DraggableViewProject
//
//  Created by 范祎楠 on 16/2/27.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import UIKit

protocol DraggableViewDelegate: NSObjectProtocol {
  
  func draggableView(numberOfCardViewInDraggableView draggableView : DraggableView) -> Int
  func draggableView(configDraggableCardView cardView: DraggableCardView, viewContentAtIndex index: Int)
  func draggableView(draggableView: DraggableView, resultIsInLeft isLeft: Bool, resultAtIndex index: Int)
  func draggableViewAllRemoved(draggableView: DraggableView)
  
}

class DraggableView: UIView {
  
  private weak var delegate: DraggableViewDelegate?
  //保存当前的cardView
  private var existCardViewList: [DraggableCardView] = []
  //保存当前存在的cardView的frame
  private var existCardViewFrameList: [CGRect] = []
  //已加载过的card的数量
  private var numberOfLoadedCard = 0
  //同时最多存在的cardView，最后一个为隐藏的，用于动画
  private var existMaxCardCount: Int = 4
  //当前最上层的卡片在所有卡片中的index
  private(set) var currentIndex = 0
  //cardView总数
  private(set) var numberOfCards: Int!
  
  //展示出来的最大卡片数量，但是需要在最后放一个隐藏的card用于动画，所以实际存在的数量是displayMaxCount＋1，也就是existMaxCardCount
  var displayMaxCount = 3 {
    didSet{
      existMaxCardCount = displayMaxCount + 1
    }
  }
  
  //底部的高度，两个card的高度差 ＝ bottomPadding ／ displayMaxCount
  var bottomPadding: CGFloat = 20
  //相邻两个卡片打大小缩放比例
  var reduceScale: CGFloat = 0.9
  //是否允许推拽
  var draggable = true
  
  
  init(frame: CGRect, delegate: DraggableViewDelegate) {
    
    self.delegate = delegate
    //    self.numberOfCards = numberOfCards
    super.init(frame: frame)
  }
  
  init(delegate: DraggableViewDelegate) {
    
    self.delegate = delegate
    //    self.numberOfCards = numberOfCards
    super.init(frame: CGRectZero)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  /**
   外部直接调用，向右移出
   */
  func rightClickAction() {
    
    guard !existCardViewList.isEmpty else { return }
    existCardViewList[0].clickMoveToRight()
    
  }
  
  /**
   外部直接调用，向左移出
   */
  func leftClickAction() {
    
    guard !existCardViewList.isEmpty else { return }
    existCardViewList[0].clickMoveToLeft()
    
  }
  
  func loadCards() {
    
    clearCardView()
    
    numberOfCards = delegate?.draggableView(numberOfCardViewInDraggableView: self) ?? 0
    
    let numOfCardToLoad = min(numberOfCards, existMaxCardCount)
    
    for _ in 0..<numOfCardToLoad {
      
      loadNextCard()
    }
  }
  
  //加载下一个卡片
  private func loadNextCard() {
    
    guard numberOfLoadedCard < numberOfCards else { return }
    
    let indexOfLoadCard = numberOfLoadedCard
    
    //设置为最大的frame，用于布局
    let cardView = DraggableCardView(frame: getCardFrameAtShowingIndex(0), delegate: self)
    //第一个设为可拖拽
    cardView.draggable = draggable == true ? indexOfLoadCard == 0 : false
    delegate?.draggableView(configDraggableCardView: cardView, viewContentAtIndex: indexOfLoadCard)
    //修改成适当的frame
    cardView.frame = getCardFrameAtShowingIndex(min(indexOfLoadCard, existMaxCardCount - 1))
    
    if indexOfLoadCard == 0 {
      addSubview(cardView)
    } else {
      
      insertSubview(cardView, belowSubview: existCardViewList.last!)
    }
    
    existCardViewList += [cardView]
    existCardViewFrameList += [cardView.frame]
    numberOfLoadedCard++
    
    if existCardViewList.count == existMaxCardCount {
      cardView.alpha = 0
    }
    
    
  }
  
  //获取卡片frame
  private func getCardFrameAtShowingIndex(index: Int) -> CGRect {
    
    //第一个卡片的size
    let firstCardSize = CGSize(width: CGRectGetWidth(frame), height: CGRectGetHeight(frame) - bottomPadding)
    
    let currentCardSize = CGSize(width: firstCardSize.width * CGFloat(pow(Double(reduceScale), Double(index))), height: firstCardSize.height * CGFloat(pow(Double(reduceScale), Double(index))))
    
    //每一层卡片y的偏移量，需要考虑最后一个隐藏卡片
    let yOffset = bottomPadding / CGFloat(displayMaxCount) * CGFloat(index)
    
    let cardFrame = CGRect(origin: CGPoint(x: (CGRectGetWidth(frame) - currentCardSize.width) / 2, y: firstCardSize.height + yOffset - currentCardSize.height), size: currentCardSize)
    
    return cardFrame
  }
  
  //计算两个值中间某个百分比位置的值
  private func calculateMidValueWith(value1: CGFloat, value2: CGFloat, progress: CGFloat) -> CGFloat {
    
    return value1 + (value2 - value1) * progress
  }
  
  private func cardViewDidDisappear() {
    
    existCardViewList.removeFirst()
    
    if existCardViewList.isEmpty {
      
      delegate?.draggableViewAllRemoved(self)
      
    } else {
      
      existCardViewList[0].draggable = true
      currentIndex++
      
    }
    
  }
  
  //清除所有数据
  private func clearCardView() {
    
    for cardView in subviews {
      cardView.removeFromSuperview()
    }
    
    existCardViewList.removeAll()
    existCardViewFrameList.removeAll()
    numberOfLoadedCard = 0
    currentIndex = 0
  }
}


extension DraggableView: DraggableCardViewDelegate {
  func draggableCardView(cardView: DraggableCardView, draggingProgress progress: CGFloat) {
    
    for index in 1..<existCardViewList.count {
      
      let upperFrame = existCardViewFrameList[index - 1]
      let currentFrame = existCardViewFrameList[index]
      
      let widthInProgress = calculateMidValueWith(currentFrame.width, value2: upperFrame.width, progress: progress)
      let heightInProgress = calculateMidValueWith(currentFrame.height, value2: upperFrame.height, progress: progress)
      let xInProgress = calculateMidValueWith(currentFrame.minX, value2: upperFrame.minX, progress: progress)
      let yInProgress = calculateMidValueWith(currentFrame.minY, value2: upperFrame.minY, progress: progress)
      
      existCardViewList[index].frame = CGRect(x: xInProgress, y: yInProgress, width: widthInProgress, height: heightInProgress)
      
    }
    
    if existCardViewList.count == existMaxCardCount {
      
      existCardViewList[existMaxCardCount - 1].alpha = progress
      
    }
  }
  
  func draggableCardViewDidRemove(cardView: DraggableCardView, isLeft: Bool) {
    
    cardView.removeFromSuperview()
    
    delegate?.draggableView(self, resultIsInLeft: isLeft, resultAtIndex: currentIndex)
    
    cardViewDidDisappear()
    loadNextCard()
    
  }
  
}