//
//  ViewController.swift
//  DraggableViewProject
//
//  Created by 范祎楠 on 16/2/27.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  var draggableView: DraggableView!
  
  var count = 5
  
  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
  }

  override func viewDidAppear(animated: Bool) {
    draggableView.reloadCards()
  }
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


  @IBAction func onClickRight() {
    
    draggableView.rightClickAction()
//    count += 5
//    draggableView.loadNewCards()

  }
  
  @IBAction func onClickLeft() {
    draggableView.leftClickAction()
  }
  
  func setupUI() {
    
    draggableView = DraggableView(dataSource: self)
    draggableView.delegate = self
    view.addSubview(draggableView)

    draggableView.displayMaxCount = 3
    
    draggableView.snp_makeConstraints { (make) -> Void in
      make.top.equalTo(view).offset(80)
      make.left.equalTo(view).offset(40)
      make.right.equalTo(view).offset(-40)
      make.bottom.equalTo(view).offset(-150)

    }
  }

}

extension ViewController: DraggableViewDataSource {
  
  func draggableView(numberOfCardViewInDraggableView draggableView: DraggableView) -> Int {
    return count
  }
  
  func draggableView(configDraggableCardView cardView: DraggableCardView, viewContentAtIndex index: Int) {
    
    cardView.layer.cornerRadius = 2
    cardView.layer.shadowRadius = 3
    cardView.layer.shadowOpacity = 0.2
    cardView.layer.shadowOffset = CGSizeMake(1, 1)
    cardView.layer.shadowColor = UIColor.hexStringToColor("333333").CGColor
    cardView.backgroundColor = UIColor.whiteColor()
    
    let avatarImageView = UIImageView(frame: CGRect(origin: CGPointZero, size: CGSize(width: cardView.frame.width, height: cardView.frame.width)))
    cardView.addSubview(avatarImageView)
    
    avatarImageView.backgroundColor = UIColor.orangeColor()
    
    let bottomView = UIView(frame: CGRect(x: 0, y: avatarImageView.frame.maxY, width: cardView.frame.width, height: cardView.frame.height - avatarImageView.frame.height))
    cardView.addSubview(bottomView)
    bottomView.backgroundColor = UIColor.whiteColor()
    
    let nameLabel = UILabel()
    bottomView.addSubview(nameLabel)
    let areaLabel = UILabel()
    bottomView.addSubview(areaLabel)
    
    nameLabel.snp_makeConstraints { (make) -> Void in
      make.top.equalTo(bottomView).offset(7)
      make.left.equalTo(bottomView).offset(10)
      make.bottom.equalTo(areaLabel.snp_top).offset(-5)
      make.height.equalTo(areaLabel.snp_height)
    }
    
    nameLabel.text = "这里是名字"
    nameLabel.font = UIFont.systemFontOfSize(14)
    
    //ageLabel
    let ageLabel = UILabel()
    bottomView.addSubview(ageLabel)
    ageLabel.snp_makeConstraints { (make) -> Void in
      make.left.equalTo(nameLabel.snp_right).offset(7)
      make.height.equalTo(nameLabel.snp_height)
      make.baseline.equalTo(nameLabel.snp_baseline)
    }
    
    ageLabel.font = UIFont.systemFontOfSize(14)
    ageLabel.text = "16岁"
    
    //areaLabel
    areaLabel.snp_makeConstraints { (make) -> Void in
      make.left.equalTo(bottomView).offset(10)
      make.bottom.equalTo(bottomView.snp_bottom).offset(-7)
      make.height.equalTo(nameLabel.snp_height)
      
    }
    
    areaLabel.font = UIFont.systemFontOfSize(12)
    areaLabel.text = "北京"
    
  }

}
extension ViewController: DraggableViewDelegate {
  
  func draggableView(cardView: DraggableView, resultIsInLeft isLeft: Bool, resultAtIndex index: Int) {
    
    print("index \(index) result \(!isLeft)")
  }
  
  func draggableViewAllRemoved(draggableView: DraggableView) {
    print("all removed")
  }
  
  func draggableViewWillDrag(draggableView: DraggableView, atIndex index: Int) -> Bool {
    print("\(index) will drag")
    
    return true
  }
  
  func draggableViewWillDisplay(draggableView: DraggableView, atIndex index: Int) {
    print("\(index) will display")
  }
}
