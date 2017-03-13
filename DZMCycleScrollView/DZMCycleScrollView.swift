//
//  DZMCycleScrollView.swift
//  DZMCycleScrollView
//
//  Created by 邓泽淼 on 2017/3/10.
//  Copyright © 2017年 DZM. All rights reserved.
//

import UIKit

@objc protocol DZMCycleScrollViewDelegate:NSObjectProtocol {
    
    /// 开始拖拽
    @objc optional func cycleScrollViewWillBeginDragging(cycleScrollView:DZMCycleScrollView)
    
    /// 结束拖拽
    @objc optional func cycleScrollViewDidEndDragging(cycleScrollView:DZMCycleScrollView)
    
    /// 正在滚动
    @objc optional func cycleScrollViewDidScroll(cycleScrollView:DZMCycleScrollView)
    
    /// 滚动到哪一个index
    @objc optional func cycleScrollView(cycleScrollView:DZMCycleScrollView,scrollToIndex index:NSInteger)
    
    /// 点击了哪一个index
    @objc optional func cycleScrollView(cycleScrollView:DZMCycleScrollView,touchToIndex index:NSInteger)
}

class DZMCycleScrollView: UIView,UIScrollViewDelegate {
    
    // MARK: -- 可使用属性
    
    /// 代理
    weak var delegate:DZMCycleScrollViewDelegate?
    
    /// true 无限滚动(views 必须至少2个)  false 不会无限滚动
    var limitScroll:Bool = false
    
    /// 初始化选中索引位置
    var initSelectIndex:NSInteger = 0
    
    /// 当前显示的索引
    var currentIndex:NSInteger = 0
    
    /// 动画时间
    var animateDuration:TimeInterval = 0.25
    
    /// 是否开启点击手势
    var openTap:Bool = true {
        
        didSet{
        
            tap.isEnabled = openTap
        }
    }
    
    /// scrollView.bounces 允许滚动控件有额外滚动区域
    var bounces:Bool = false {
        
        didSet{
            
            scrollView.bounces = bounces
        }
    }
    
    
    // MARK: -- 私有属性
    
    /// views
    private var views:[UIView] = []
    
    /// 滚动View
    private var scrollView:UIScrollView!
    
    /// 点击手势
    private var tap:UITapGestureRecognizer!
    
    /// 拖拽
    private var IsDragging:Bool = false
    
    /// 初始化完成
    private var isInitComplete:Bool = false
    
    /// 辅助值 勿动
    private let TempNumberOne:NSInteger = 1
    private let TempNumberTwo:NSInteger = 2

    // 临时记录 用于next()
    private var tempPoint:CGPoint? = nil
    
    /// 初始化方法
    class func cycleScrollView(views:[UIView],limitScroll:Bool) ->DZMCycleScrollView {
        
        let cycleScrollView = DZMCycleScrollView()
        
        cycleScrollView.limitScroll = limitScroll
        
        cycleScrollView.setupViews(views: views)
        
        return cycleScrollView;
    }
    
    /// 初始化方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initSub()
    }
    
    /// 初始化
    private func initSub() {
     
        // scrollView
        scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.delegate = self
        scrollView.bounces = bounces
        addSubview(scrollView)
        
        // 点击手势
        tap = UITapGestureRecognizer(target: self, action: #selector(DZMCycleScrollView.clickTap(tap:)))
        addGestureRecognizer(tap)
    }
    
    /// 下一页
    func next() {
        
        let count = views.count
        
        if count > TempNumberOne { // 最少一个
            
            IsDragging = false
            
            if tempPoint != nil { // 直接完成未完成的操作
                
                scrollView.contentOffset = tempPoint!
                
                tempPoint = nil
                
                synchronization(scrollView)
            }
            
            UIView.animate(withDuration: animateDuration, animations: { [weak self] ()->Void in
                
                if self != nil {
                    
                    if self!.limitScroll { // 无限滚动
                        
                        self?.tempPoint = CGPoint(x: self!.scrollView.contentOffset.x + self!.frame.size.width, y: 0)
                        
                    }else{ // 非无限滚动
                        
                        if self!.currentIndex == (count - self!.TempNumberOne) {
                            
                            self?.tempPoint = CGPoint(x: 0, y: 0)
                            
                        }else{
                            
                            self?.tempPoint = CGPoint(x: self!.scrollView.contentOffset.x + self!.frame.size.width, y: 0)
                        }
                    }
                    
                    self?.scrollView.contentOffset = self!.tempPoint!
                }
                
                }, completion: {[weak self] (isOK) in
                    
                    self?.tempPoint = nil
                    
                    self?.synchronization(self!.scrollView)
            })
        }
    }
    
    
    /// 手动选择显示对象 可选择动画
    func selectIndex(index:NSInteger,animated:Bool) {
        
        if views.count > TempNumberOne && isInitComplete && (index >= 0 && index < views.count){ // 小于数组个数
            
            IsDragging = false
            
            var tempIndex = index
            
            if limitScroll { // 无限滚动
                
                tempIndex += TempNumberOne
           
                setSubviewFrame()
            }
            
            if index != currentIndex {
                
                // 动画时间
                let duration = animated ? animateDuration : 0
                
                let w = frame.size.width
                
                UIView.animate(withDuration: duration, animations: { [weak self] ()->Void in
                    
                    self?.scrollView.contentOffset = CGPoint(x: CGFloat(tempIndex) * w, y: 0)
                    
                    }, completion: {[weak self] (isOK) in
                        
                        self?.IsDragging = true
                        
                        self?.synchronization(self!.scrollView)
                })
            }
        }
    }
    
    /// 创建 以及 重置 显示数组
    func setupViews(views:[UIView]) {
        
        // 清空
        for subview in scrollView.subviews {
            
            subview.removeFromSuperview()
        }
        
        // 记录最新的views
        self.views = views;
        
        // 添加
        for subview in views {
            
            scrollView.addSubview(subview)
        }
        
        // 布局
        setNeedsLayout()
    }
    
    /// 通过 view 获取截屏图片
    private func imageWithView(view:UIView?) ->UIImage? {
        
        var image:UIImage? = nil
        
        if (view != nil) {
            
            UIGraphicsBeginImageContextWithOptions(view!.frame.size, false, 0.5)
            
            let context = UIGraphicsGetCurrentContext()
            
            if (context != nil) {
                
                view!.layer.render(in: context!)
                
                image = UIGraphicsGetImageFromCurrentImageContext()
                
            }
            
            UIGraphicsEndImageContext()
        }
        
        return image
    }
    
    /// scrollView layoutSubviews
    private func scrollViewSetNeedsLayout() {
        
        // 属性值
        let w = frame.size.width
        let h = frame.size.height
        let count = views.count
        
        // frame
        setSubviewFrame()
        
        // contentSize
        if (limitScroll && (count > TempNumberOne)) {
            
            scrollView.contentSize = CGSize(width: CGFloat(count + TempNumberTwo) * w, height: h)
            
            scrollView.contentOffset = CGPoint(x:CGFloat(TempNumberOne) * w, y: 0)
            
        }else{
            
            scrollView.contentSize = CGSize(width: CGFloat(count) * w, height: h)
        }
        
        // 是否为初始化 
        if !isInitComplete {
           
            isInitComplete = true
            
            // 初始化选中一次
            selectIndex(index: initSelectIndex, animated: false)
        }
        
        
        // 默认选中一次
        synchronization(scrollView)
    }
    
    /// 设置 views Frame
    private func setSubviewFrame() {
        
        // 属性值
        let w = frame.size.width
        let h = frame.size.height
        let count = views.count
        
        // frame
        for i in 0..<count {
            
            let subview = views[i]
            
            // 允许无限滚动的时候需要有至少2个View
            if (limitScroll && (count > TempNumberOne)) {
                
                subview.frame = CGRect(x: CGFloat(i + TempNumberOne) * w, y: 0, width: w, height: h)
                
            }else{
                
                subview.frame = CGRect(x: CGFloat(i) * w, y: 0, width: w, height: h)
            }
        }
    }
    
    /// layoutSubviews
    override func layoutSubviews() {
        super.layoutSubviews()

        // 滚动区域
        scrollView.frame = bounds
        
        // 布局
        scrollViewSetNeedsLayout()
    }
    
    /// 手势点击
    func clickTap(tap:UITapGestureRecognizer) {
        
        if (views.count > 0) {
            
            delegate?.cycleScrollView?(cycleScrollView: self, touchToIndex: currentIndex)
        }
    }
    
    // MARK: -- UIScrollViewDelegate
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

        IsDragging = true
        
        delegate?.cycleScrollViewWillBeginDragging?(cycleScrollView: self)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        delegate?.cycleScrollViewDidEndDragging?(cycleScrollView: self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if IsDragging {
            
            synchronization(scrollView)
        }
        
        delegate?.cycleScrollViewDidScroll?(cycleScrollView: self)
    }
    
    /// 计算位置
    
    var TempCurrentIndex = 99 // 临时记录值 只要比 views.count 大即可
    
    func synchronization(_ scrollView: UIScrollView) {
      
        currentIndex = NSInteger(scrollView.contentOffset.x / frame.size.width + 0.5)
        
        if (limitScroll && (views.count > TempNumberOne)) {
            
            let w = frame.size.width
            let h = frame.size.height
            let x = scrollView.contentOffset.x
            let count = views.count
          
            if (IsDragging) { // 拖拽
                
                if views.count == TempNumberTwo {
                    
                    if x < w {
                        
                        views.last?.frame = CGRect(x: 0, y: 0, width: w, height: h)
                        
                        views.first?.frame = CGRect(x: w, y: 0, width: w, height: h)
                        
                    }else if (x >= CGFloat(count) * w) {
                        
                        views.last?.frame = CGRect(x: CGFloat(count) * w, y: 0, width: w, height: h)
                        
                        views.first?.frame = CGRect(x: CGFloat(count + TempNumberOne) * w, y: 0, width: w, height: h)
                        
                    }else if (x < CGFloat(count) * w) {
                        
                        views.last?.frame = CGRect(x: CGFloat(count) * w, y: 0, width: w, height: h)
                        
                        views.first?.frame = CGRect(x: w, y: 0, width: w, height: h)
                        
                    }else{}
                    
                }else{
                    
                    if x < (CGFloat(TempNumberTwo) * w + 0.1) {
                        
                        views.last?.frame = CGRect(x: 0, y: 0, width: w, height: h)
                        
                        views.first?.frame = CGRect(x: w, y: 0, width: w, height: h)
                    }
                    
                    if x > (CGFloat(views.count - TempNumberOne) * w) {
                        
                        views.last?.frame = CGRect(x: CGFloat(count) * w, y: 0, width: w, height: h)
                        
                        views.first?.frame = CGRect(x: CGFloat(count + TempNumberOne) * w, y: 0, width: w, height: h)
                    }
                }
                
                if (x < 0.1) {
                    
                    scrollView.contentOffset = CGPoint(x:CGFloat(count) * w, y: 0)
                    
                    synchronization(scrollView)
                    
                    return
                }
                
                if (x > (scrollView.contentSize.width - frame.size.width - 0.1)) {
                    
                    scrollView.contentOffset = CGPoint(x: w, y: 0)
                    
                    synchronization(scrollView)
                    
                    return
                }
                
            }else{ // next
                
                if count == TempNumberTwo {
                    
                    if currentIndex == TempNumberOne {
                        
                        views.first?.frame = CGRect(x: w, y: 0, width: w, height: h)
                        
                        views.last?.frame = CGRect(x: CGFloat(TempNumberTwo) * w, y: 0, width: w, height: h)
                        
                    }
                    
                    if currentIndex == count {
                        
                        views.first?.frame = CGRect(x: CGFloat(count + TempNumberOne) * w, y: 0, width: w, height: h)
                        
                        views.last?.frame = CGRect(x: CGFloat(TempNumberTwo) * w, y: 0, width: w, height: h)
                        
                    }
                    
                }else{
                   
                    if currentIndex == TempNumberOne {
                        
                        views.last?.frame = CGRect(x: 0, y: 0, width: w, height: h)
                        
                        views.first?.frame = CGRect(x: w, y: 0, width: w, height: h)
                    }
                    
                    if currentIndex == (count - TempNumberOne) {
                        
                        views.last?.frame = CGRect(x: CGFloat(count) * w, y: 0, width: w, height: h)
                        
                        views.first?.frame = CGRect(x: CGFloat(count + TempNumberOne) * w, y: 0, width: w, height: h)
                    }
                }
                
                if currentIndex == 0 {
                    
                    scrollView.contentOffset = CGPoint(x:CGFloat(count) * w ,y: 0)
                    
                    synchronization(scrollView);
                    
                    return
                }
                
                if currentIndex == count + TempNumberOne {
                    
                    scrollView.contentOffset = CGPoint(x:w ,y: 0)
                    
                    synchronization(scrollView);
                    
                    return
                }
            }
            
            if (currentIndex == 0) {
                
                currentIndex = views.count
            }
            
            if (currentIndex == (views.count + TempNumberOne)) {
                
                currentIndex = TempNumberOne
            }
            
            currentIndex -= TempNumberOne
            
        }
        
        if (views.count > 0 && currentIndex != TempCurrentIndex) {
            
            TempCurrentIndex = currentIndex
            
            delegate?.cycleScrollView?(cycleScrollView: self, scrollToIndex: currentIndex)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }

}
