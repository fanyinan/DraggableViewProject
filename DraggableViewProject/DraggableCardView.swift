//
//  DraggableComponentView.swift
//  DraggableViewProject
//
//  Created by 范祎楠 on 16/2/27.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import UIKit

protocol DraggableCardViewDelegate: NSObjectProtocol {
  
  func draggableCardView(cardView: DraggableCardView, draggingProgress progress: CGFloat)
  func draggableCardViewDidRemove(cardView: DraggableCardView, isLeft: Bool)
  func draggableCardViewWillDrag(cardView: DraggableCardView) -> Bool
  
}

class DraggableCardView: UIView {
  
  private weak var delegate: DraggableCardViewDelegate?
  private let viewMoveDistane = UIScreen.mainScreen().bounds.width
  private let maxRadian: CGFloat = CGFloat(M_PI / 5) //最大弧度
  private var pan: UIPanGestureRecognizer!
  
  //保存subviews最初frame，也就是最大是的frame
  private var subViewOriginFrameDic: [Int: CGRect] = [:]
  //保存subview的label的最初字号，也就是最大时的字号
  private var subViewOriginFontSizeDic: [Int: CGFloat] = [:]
  //保存view的最大宽度，用于实时缩放样式
  private static var maxWidth: CGFloat!
  //进行动画的时候，不允许再次开始动画
  private var isAnimating = false
  
  var originCenter: CGPoint!
  var touchOffsetPoint: CGPoint!
  var selectedCriticalScale: CGFloat = 2 / 3
  
  var draggable = false {
    didSet{
      
      if draggable {
        pan = UIPanGestureRecognizer(target: self, action: "onDragging:")
        addGestureRecognizer(pan)
        
        
      } else {
        guard pan != nil else { return }
        removeGestureRecognizer(pan)
      }
      
    }
  }
  
  lazy var displayLink: CADisplayLink = {
    
    let displayLink = CADisplayLink(target: self, selector: "updateLoop")
    displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    return displayLink
    
  }()
  
  
  init(frame: CGRect, delegate: DraggableCardViewDelegate) {
    super.init(frame: frame)
    
    self.delegate = delegate
    setAnchorPoint(CGPoint(x: 0.5, y: 1))
    
  }
  
  deinit{
    print("DraggableCardView deinit")
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    
    guard DraggableCardView.maxWidth != frame.width else { return }
    
    if subViewOriginFrameDic.isEmpty {
      saveOriginFrame(self)
    }
    
    if DraggableCardView.maxWidth == nil {
      DraggableCardView.maxWidth = frame.width
    }
    
    guard !draggable else { return }
    
    let scale = frame.size.width / DraggableCardView.maxWidth
    
    resizeView(self, scale: scale)
    
  }
  
  
  func clickMoveToRight() {
    
    guard !isAnimating else { return }
    guard !isDragging() else { return }
    
    guard delegate?.draggableCardViewWillDrag(self) ?? true else { return }
    
    originCenter = center
    
    startLoop()
    
    isAnimating = true
    UIView.animateWithDuration(0.4, animations: { () -> Void in
      
      self.transform = CGAffineTransformMakeRotation(self.maxRadian)
      self.center = CGPoint(x: self.getRightEndPointX(), y: self.center.y)
      
      }) { _ in
        
        self.isAnimating = false
        self.endLoop()
        self.displayLink.invalidate()
        self.delegate?.draggableCardViewDidRemove(self, isLeft: false)
        
    }
  }
  
  func clickMoveToLeft() {
    
    guard !isAnimating else { return }
    guard !isDragging() else { return }
    
    guard delegate?.draggableCardViewWillDrag(self) ?? true else { return }
    
    originCenter = center
    
    startLoop()
    
    isAnimating = true
    UIView.animateWithDuration(0.4, animations: { () -> Void in
      
      self.transform = CGAffineTransformMakeRotation(-self.maxRadian)
      self.center = CGPoint(x: self.getLeftEndPointX(), y: self.center.y)
      
      }) { _ in
        
        self.isAnimating = false
        self.endLoop()
        self.displayLink.invalidate()
        self.delegate?.draggableCardViewDidRemove(self, isLeft: true)
    }
  }
  
  func onDragging(gestureRecognizer: UIPanGestureRecognizer) {
    
    touchOffsetPoint = gestureRecognizer.translationInView(self)
    
    switch gestureRecognizer.state {
    case .Began:
      
      originCenter = self.center
      
    case .Changed:
      
      center = CGPoint(x: originCenter.x + touchOffsetPoint.x, y: originCenter.y + touchOffsetPoint.y)
      
      let progress = touchOffsetPoint.x / viewMoveDistane
      transform = CGAffineTransformMakeRotation(progress * maxRadian)
      
      delegate?.draggableCardView(self, draggingProgress: fabs(progress))
      
    case .Ended:
      
      didEndDrag()
    default:
      break
    }
  }
  
  func updateLoop() {
    
    let progress = (layer.presentationLayer()!.position.x - originCenter.x) / viewMoveDistane
    
    delegate?.draggableCardView(self, draggingProgress: fabs(progress))
    
  }
  
  func setSubViewsHide(isHide: Bool) {
    
    for view in subviews {
      view.hidden = isHide
    }
  }
  
  //松手之后的操作
  private func didEndDrag() {
    
    if touchOffsetPoint.x > getCriticalWidth() {
      
      dragMoveToRight()
      
    } else if touchOffsetPoint.x < -getCriticalWidth() {
      
      dragMoveToLeft()
      
    } else {
      
      restore()
    }
  }
  
  //向右移出
  private func dragMoveToRight() {
    
    let finishPoint = CGPointMake(getRightEndPointX(), 2 * touchOffsetPoint.y + originCenter.y);
    
    startLoop()
    
    isAnimating = true
    UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: { () -> Void in
      
      self.center = finishPoint
      
      }) { (finish) -> Void in
        
        self.isAnimating = false
        self.endLoop()
        self.displayLink.invalidate()
        self.delegate?.draggableCardViewDidRemove(self, isLeft: false)
        
    }
  }
  
  //向左移出
  private func dragMoveToLeft() {
    
    let finishPoint = CGPointMake(getLeftEndPointX(), 2 * touchOffsetPoint.y + originCenter.y);
    
    startLoop()
    
    isAnimating = true
    UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: { () -> Void in
      
      self.center = finishPoint
      
      }) { (finish) -> Void in
        
        self.isAnimating = false
        self.endLoop()
        self.displayLink.invalidate()
        self.delegate?.draggableCardViewDidRemove(self, isLeft: true)
        
    }
  }
  
  //还原
  private func restore() {
    
    startLoop()
    
    isAnimating = true
    UIView.animateWithDuration(0.3, animations: { () -> Void in
      self.center = self.originCenter
      self.transform = CGAffineTransformIdentity
      }) { (finish) -> Void in
        
        self.isAnimating = false
        self.endLoop()
    }
  }
  
  //获得是移出还是还原的位移的临界宽度
  private func getCriticalWidth() -> CGFloat {
    return CGRectGetWidth(frame) / 2 * selectedCriticalScale
  }
  
  //获取左侧移出的终点
  private func getLeftEndPointX() -> CGFloat {
    
    return originCenter.x - viewMoveDistane
  }
  
  //获取右侧移出的终点
  private func getRightEndPointX() -> CGFloat {
    
    return originCenter.x + viewMoveDistane
  }
  
  private func setAnchorPoint(anchorPoint: CGPoint) {
    
    let oldOrigin = frame.origin;
    layer.anchorPoint = anchorPoint;
    let newOrigin = frame.origin;
    
    var originOffset = CGPointZero
    originOffset.x = newOrigin.x - oldOrigin.x;
    originOffset.y = newOrigin.y - oldOrigin.y;
    
    center = CGPointMake (center.x - originOffset.x, center.y - originOffset.y);
  }
  
  private func startLoop() {
    displayLink.paused = false
  }
  
  private func endLoop() {
    
    displayLink.paused = true
    
  }
  
  private func saveOriginFrame(superView: UIView) {
    
    for subview in superView.subviews {
      
      saveOriginFrame(subview)
      
      subViewOriginFrameDic[subview.hash] = subview.frame
      
      if let label = subview as? UILabel {
        subViewOriginFontSizeDic[subview.hash] = label.font.pointSize
      }
    }
    
  }
  
  private func resizeView(superView: UIView, scale: CGFloat) {
    
    for subview in superView.subviews {
      
      resizeView(subview, scale: scale)
      
      subview.frame = calculateFrameWith(subViewOriginFrameDic[subview.hash]!, scale: scale)
      
      if let label = subview as? UILabel {
        let pointSize = subViewOriginFontSizeDic[subview.hash]! * scale

        //减小字号的小数位，不然内存剧增而且无法释放
        label.font = UIFont.systemFontOfSize(CGFloat(CGFloat(Int(pointSize / 0.1)) * 0.1))
      }
      
    }
  }
  
  private func calculateFrameWith(originFrame: CGRect, scale: CGFloat) -> CGRect {
    
    var finalFrame = originFrame
    finalFrame.origin = CGPoint(x: originFrame.origin.x * scale, y: originFrame.origin.y * scale)
    finalFrame.size = CGSize(width: originFrame.size.width * scale, height: originFrame.size.height * scale)
    
    return finalFrame
    
  }
  
  //是否正在拖拽
  private func isDragging() -> Bool {
    
    return [.Began,.Changed].contains(pan.state)
  }
  
}

extension DraggableCardView: UIGestureRecognizerDelegate {
  override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    return delegate?.draggableCardViewWillDrag(self) ?? true
  }
}
