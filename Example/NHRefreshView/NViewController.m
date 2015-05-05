//
//  NViewController.m
//  NHRefreshView
//
//  Created by Naithar on 05/05/2015.
//  Copyright (c) 2014 Naithar. All rights reserved.
//

#import "NViewController.h"
#import <NHRefreshView.h>

@interface NViewController ()<UITableViewDataSource, UITableViewDelegate, NHRefreshViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NHRefreshView *topRefreshView;
@property (strong, nonatomic) NHRefreshView *bottomRefreshView;

@end

@implementation NViewController

- (BOOL)refreshView:(NHRefreshView *)refreshView shouldChangeInsetsForScrollView:(UIScrollView *)scrollView withValue:(UIEdgeInsets)refreshViewInsets {
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.contentInset = UIEdgeInsetsMake(200, 0, 215, 0);


    self.topRefreshView = [[NHRefreshView alloc] initWithScrollView:self.tableView refreshBlock:^(NHRefreshView *refreshView){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [refreshView stopRefreshing];
        });
    }];

    self.topRefreshView.delegate = self;

    self.bottomRefreshView = [[NHRefreshView alloc] initWithScrollView:self.tableView direction:NHRefreshViewDirectionBottom refreshBlock:^(NHRefreshView *refreshView){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [refreshView stopRefreshing];
        });
    }];


    [self.view layoutIfNeeded];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
}

- (void)dealloc {
//    [self.topRefreshView removeFromSuperview];
}

@end

////
////  SKRefreshView.swift
////  Shake-IOS
////
////  Created by Naithar on 29.08.14.
////  Copyright (c) 2014 ITC-Project. All rights reserved.
////
//
//import UIKit
//
//@objc
//public class SKRefreshView: NSObject {
//
//    let imageViewHeight : CGFloat = 29
//    let imageName = "loading-red.png"
//
//    weak var scrollViewSuperview : UIScrollView!
//    weak var scrollViewDelegate : NSObject!
//    var loadingViewSuperview : UIView!
//    var loadingImageView : UIImageView!
//    var heightConstraint : NSLayoutConstraint!
//    var originalTopInset : CGFloat = 0
//    var originalBottomInset : CGFloat = 0
//
//    func resetInsetsOnOriginalInset() -> Bool {
//
//        if self.isBottom
//            && self.waitingForResults
//            && self.onceToken != 0 {
//                self.scrollViewSuperview.contentInset.bottom = max(self.scrollViewSuperview.bounds.height - self.scrollViewSuperview.contentSize.height + self.loadingOffset, self.originalBottomInset + self.loadingOffset)
//                return true
//            }
//
//        return false
//    }
//
//    var isBottom : Bool = false
//
//    var maxOffset : CGFloat = 80
//    var loadingOffset : CGFloat = 80
//
//    var refreshing : Bool = false
//
//    var refreshAction : (() -> ())?
//
//    private var onceToken : dispatch_once_t = 0
//    var waitingForResults : Bool = false
//
//    convenience init(scrollView: UIScrollView!, delegate: NSObject!, isBottom : Bool = false, refreshBlock: (() -> ())?) {
//        self.init(scrollView: scrollView, delegate: delegate, isBottom: isBottom)
//
//        self.refreshAction = refreshBlock
//    }
//
//    init(scrollView: UIScrollView!, delegate: NSObject!, isBottom : Bool = false) {
//
//        super.init()
//
//        self.isBottom = isBottom
//
//        self.loadingViewSuperview = UIView(
//                                           frame: CGRect(
//                                                         x: 0,
//                                                         y: !isBottom ? -(scrollView.contentInset.top+self.imageViewHeight) : max(scrollView.bounds.height - scrollView.contentInset.bottom, scrollView.contentSize.height),
//                                                         width: scrollView.frame.width,
//                                                         height: self.imageViewHeight))
//
//        self.loadingImageView = UIImageView(image: UIImage(named: self.imageName))
//        self.loadingImageView.contentMode = .Center;
//        self.loadingImageView.frame.size = CGSize(width: self.imageViewHeight, height: self.imageViewHeight)
//        self.loadingViewSuperview.clipsToBounds = true
//
//        self.loadingViewSuperview.addSubview(self.loadingImageView)
//        self.loadingViewSuperview.backgroundColor = UIColor.clearColor()
//        scrollView.addSubview(self.loadingViewSuperview)
//
//        self.scrollViewSuperview = scrollView
//
//        self.originalTopInset = self.scrollViewSuperview.contentInset.top
//        self.originalBottomInset = self.scrollViewSuperview.contentInset.bottom
//
//        RACObserve(self.scrollViewSuperview, "contentOffset").subscribeNext { (data: AnyObject!) -> Void in
//            self.scrollViewDidScroll(self.scrollViewSuperview)
//        }
//
//        self.scrollViewDelegate = delegate
//        self.scrollViewDelegate.rac_signalForSelector("scrollViewDidEndDragging:willDecelerate:", fromProtocol: NSProtocolFromString("UIScrollViewDelegate")).subscribeNext { (data: AnyObject!) -> Void in
//            self.scrollViewDidEndDragging(data[0] as UIScrollView)
//        }
//    }
//
//    func updateTopRefreshView(scrollView: UIScrollView!) -> CGFloat {
//
//        var offsetValue = scrollView.contentOffset.y + self.originalTopInset
//        self.loadingViewSuperview.center.x = scrollView.bounds.width / 2
//        self.loadingViewSuperview.frame.size.height = max(self.imageViewHeight, self.imageViewHeight - offsetValue)
//        self.loadingViewSuperview.frame.origin.y = -(self.loadingViewSuperview.frame.height+self.originalTopInset)
//        self.loadingViewSuperview.frame.size.width = scrollView.frame.width
//
//        self.loadingImageView.center = CGPoint(
//                                               x: self.loadingViewSuperview.bounds.width / 2,
//                                               y: self.loadingViewSuperview.bounds.height / 2 + self.imageViewHeight / 2)
//        return offsetValue
//    }
//
//    func updateBottomRefreshView(scrollView: UIScrollView) -> CGFloat {
//        self.loadingViewSuperview.center.x = scrollView.bounds.width / 2
//        var offsetValue = (scrollView.contentOffset.y + scrollView.bounds.height) - max(scrollView.bounds.height, scrollView.contentSize.height + self.originalBottomInset)
//
//        self.loadingViewSuperview.frame.size.height = max(self.imageViewHeight, self.imageViewHeight + offsetValue)
//        self.loadingViewSuperview.frame.origin.y = max(scrollView.bounds.height - self.originalBottomInset, scrollView.contentSize.height)
//        self.loadingViewSuperview.frame.size.width = scrollView.bounds.width
//
//        self.loadingImageView.center = CGPoint(
//                                               x: self.loadingViewSuperview.bounds.width / 2,
//                                               y: self.loadingViewSuperview.bounds.height / 2 - self.imageViewHeight / 2)
//
//        return offsetValue
//    }
//
//    func scrollViewDidScroll(scrollView: UIScrollView!) {
//        if !self.isBottom
//            && scrollView.contentOffset.y < 0
//            && scrollView.isEqual(self.loadingViewSuperview.superview) {
//
//                var offsetValue = self.updateTopRefreshView(scrollView)
//
//                if !self.loadingImageView.layer.animationForKey("rotationAnimation") {
//                    var scrollValue = (-Double(self.maxOffset) - Double(offsetValue)) / Double(self.maxOffset)
//                    var anglePart : Double = scrollValue * M_PI * 2
//                    self.loadingImageView.transform = CGAffineTransformMakeRotation( CGFloat(anglePart) )
//
//                    self.loadingImageView.alpha = CGFloat(1.0 + scrollValue)
//                }
//
//                if offsetValue < -self.maxOffset
//                    && scrollView.contentInset.top == self.originalTopInset {
//                        if !self.refreshing {
//                            self.startRefreshing()
//                        }
//                    }
//            }
//
//        if self.isBottom
//            && scrollView.contentOffset.y > 0
//            && scrollView.isEqual(self.loadingViewSuperview.superview) {
//
//                var offsetValue = self.updateBottomRefreshView(scrollView)
//
//                if !self.loadingImageView.layer.animationForKey("rotationAnimation") {
//                    var scrollValue = (-Double(self.maxOffset) + Double(offsetValue)) / Double(self.maxOffset)
//                    var anglePart : Double = scrollValue * M_PI * 2
//                    self.loadingImageView.transform = CGAffineTransformMakeRotation( CGFloat(anglePart) )
//                    self.loadingImageView.alpha = CGFloat(1.0 + scrollValue)
//                }
//
//                if offsetValue > self.maxOffset
//                    && scrollView.contentInset.bottom == self.originalBottomInset {
//                        if !self.refreshing {
//                            self.startRefreshing()
//                        }
//                    }
//
//            }
//
//        if !self.isBottom
//            && scrollView.contentOffset.y >= 0
//            && scrollView.isEqual(self.loadingViewSuperview.superview)
//            && !!self.loadingImageView.layer.animationForKey("rotationAnimation")
//            && self.onceToken == 0 {
//                self.stopRefreshing()
//            }
//
//        if self.isBottom
//            && scrollView.contentOffset.y <= max(0, scrollView.contentSize.height - scrollView.bounds.height + self.originalBottomInset)
//            && scrollView.isEqual(self.loadingViewSuperview.superview)
//            && !!self.loadingImageView.layer.animationForKey("rotationAnimation")
//            && self.onceToken == 0 {
//                self.stopRefreshing()
//            }
//    }
//
//    func scrollViewDidEndDragging(scrollView: UIScrollView!) {
//        if !self.isBottom &&
//            !!self.loadingImageView.layer.animationForKey("rotationAnimation")
//            && self.refreshing
//            && scrollView.contentInset.top == self.originalTopInset
//            && scrollView.isEqual(self.loadingViewSuperview.superview)
//            && self.updateTopRefreshView(scrollView) <= self.loadingOffset {
//
//                dispatch_once(&self.onceToken) {
//                    self.waitingForResults = true
//                    scrollView.bounces = false
//                    UIView.animateWithDuration(
//                                               0.3,
//                                               delay: 0,
//                                               options: UIViewAnimationOptions.BeginFromCurrentState|UIViewAnimationOptions.AllowUserInteraction,
//                                               animations: {
//                                                   scrollView.contentInset.top = self.originalTopInset + self.loadingOffset
//                                                   scrollView.contentOffset.y = -(self.originalTopInset + self.loadingOffset)
//                                               }, completion: {
//                                                   _ in
//
//                                                   scrollView.bounces = true
//                                                   self.updateTopRefreshView(scrollView)
//                                                   dispatch_after(dispatch_get_time(0.15), dispatch_get_main_queue()) {
//                                                       //                                if self.refreshing {
//                                                       self.refreshAction?()
//                                                       //                                }
//
//                                                       return
//                                                   }
//                                                   return
//                                               })
//                }
//            }
//
//        if self.isBottom &&
//            !!self.loadingImageView.layer.animationForKey("rotationAnimation")
//            && self.refreshing
//            && scrollView.contentInset.bottom == self.originalBottomInset
//            && scrollView.isEqual(self.loadingViewSuperview.superview)
//            && self.updateBottomRefreshView(scrollView) >= self.loadingOffset {
//                dispatch_once(&self.onceToken) {
//                    self.waitingForResults = true
//                    scrollView.bounces = false
//                    UIView.animateWithDuration(
//                                               0.3,
//                                               delay: 0,
//                                               options: UIViewAnimationOptions.BeginFromCurrentState|UIViewAnimationOptions.AllowUserInteraction,
//                                               animations: {
//                                                   scrollView.contentInset.bottom = max(scrollView.bounds.height - scrollView.contentSize.height + self.loadingOffset, self.originalBottomInset + self.loadingOffset)
//                                                   //                            self.updateBottomRefreshView(scrollView)
//                                               }, completion: {
//                                                   _ in
//
//                                                   scrollView.bounces = true
//                                                   self.updateBottomRefreshView(scrollView)
//                                                   dispatch_after(dispatch_get_time(0.15), dispatch_get_main_queue()) {
//
//                                                       //                                if self.refreshing {
//                                                       self.refreshAction?()
//                                                       //                                }
//
//                                                       return
//                                                   }
//                                                   return
//                                               })
//                    
//                    
//                }
//            }
//    }
//    
//    func stopRefreshing() {
//        
//        //        //NSLog("self = \(self)\n\(self.scrollViewSuperview)")
//        
//        if !self.loadingImageView.layer.animationForKey("rotationAnimation")
//            || !self.refreshing {
//                return
//            }
//        
//        self.loadingImageView.layer.removeAnimationForKey("rotationAnimation")
//        self.refreshing = false
//        
//        UIView.animateWithDuration(
//                                   0.3,
//                                   delay: 0,
//                                   options: UIViewAnimationOptions.BeginFromCurrentState|UIViewAnimationOptions.AllowUserInteraction,
//                                   animations: {
//                                       if !self.isBottom {
//                                           self.scrollViewSuperview.contentInset.top = self.originalTopInset
//                                       }
//                                       else {
//                                           self.scrollViewSuperview.contentInset.bottom = self.originalBottomInset
//                                       }
//                                   }, completion: nil)
//        
//        
//        
//        self.onceToken = 0
//        self.waitingForResults = false
//    }
//    
//    func startRefreshing() {
//        if !!self.loadingImageView.layer.animationForKey("rotationAnimation")
//            || self.refreshing {
//                return
//            }
//        
//        var rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
//        rotationAnimation.toValue = M_PI * 2.1
//        rotationAnimation.duration = 0.75
//        rotationAnimation.removedOnCompletion = false
//        rotationAnimation.cumulative = true;
//        rotationAnimation.repeatCount = HUGE;
//        
//        self.loadingImageView.transform = CGAffineTransformMakeRotation(0)
//        self.loadingImageView.layer.addAnimation(rotationAnimation, forKey: "rotationAnimation")
//        
//        self.refreshing = true
//    }
//    }

