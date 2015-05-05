//
//  NHRefreshView.m
//  Pods
//
//  Created by Naithar on 05.05.15.
//
//

#import "NHRefreshView.h"

@interface NHRefreshView ()

@property (nonatomic, weak) UIScrollView *scrollView;

@property (nonatomic, assign) NHRefreshViewDirection direction;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSLayoutConstraint *viewVerticalConstraint;
@property (nonatomic, strong) NSLayoutConstraint *viewHeightConstraint;

@property (nonatomic, assign) BOOL refreshPossible;
@property (nonatomic, assign) BOOL refreshing;
@end

@implementation NHRefreshView

- (instancetype)initWithScrollView:(UIScrollView*)scrollView {
    return [self initWithScrollView:scrollView
                          direction:NHRefreshViewDirectionTop];
}
- (instancetype)initWithScrollView:(UIScrollView*)scrollView
                         direction:(NHRefreshViewDirection)direction {
    self = [super initWithFrame:CGRectZero];

    if (self) {
        _scrollView = scrollView;
        _direction = direction;
        _maxOffset = 100;
        [self commonInit];
    }

    return self;
}

- (void)commonInit {

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.scrollView.subviews.firstObject addSubview:self];

    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.scrollView.subviews.firstObject
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1.0 constant:0]];

    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.scrollView.subviews.firstObject
                                                                attribute:NSLayoutAttributeWidth
                                                               multiplier:1.0
                                                                 constant:0]];

    self.viewVerticalConstraint = [NSLayoutConstraint constraintWithItem:self
                                                               attribute: (self.direction == NHRefreshViewDirectionTop
                                                                           ? NSLayoutAttributeBottom
                                                                           : NSLayoutAttributeTop)
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.scrollView.subviews.firstObject
                                                               attribute:(self.direction == NHRefreshViewDirectionTop
                                                                          ? NSLayoutAttributeTop
                                                                          : NSLayoutAttributeBottom)
                                                              multiplier:1.0 constant:0];

    [self.scrollView addConstraint:self.viewVerticalConstraint];

    self.viewHeightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeHeight
                                                            multiplier:0
                                                              constant:0];

    [self addConstraint:self.viewHeightConstraint];

    self.backgroundColor = [UIColor redColor];

    self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.imageView.image = [UIImage imageNamed:@"NHRefreshView.loading.png"];
    self.imageView.contentMode = UIViewContentModeCenter;
    self.imageView.backgroundColor = [UIColor greenColor];
    [self.imageView setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self addSubview:self.imageView];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0 constant:0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0 constant:0]];

    [self.scrollView setNeedsUpdateConstraints];
    [self.scrollView setNeedsLayout];

    [self.scrollView addObserver:self
                      forKeyPath:@"contentOffset"
                         options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                         context:nil];

    [self.scrollView.panGestureRecognizer addTarget:self action:@selector(panGestureAction:)];
    self.hidden = YES;
    self.clipsToBounds = YES;
}

- (void)panGestureAction:(UIPanGestureRecognizer*)recognizer {

    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            if (self.refreshPossible) {
                [self startRefreshing];
            }
            break;
        default:
            break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.scrollView) {
        if ([keyPath isEqualToString:@"contentOffset"]) {
            CGPoint oldValue = [change[NSKeyValueChangeOldKey] CGPointValue];
            CGPoint newValue = [change[NSKeyValueChangeNewKey] CGPointValue];

            if (!CGPointEqualToPoint(oldValue, newValue)) {
                if (self.direction == NHRefreshViewDirectionTop) {
                    if (newValue.y < 0) {
                        self.viewHeightConstraint.constant = -newValue.y;
                        self.hidden = NO;

                        if (!self.refreshing) {
                            [self changeAlphaAndRotation:-newValue.y];

                            if (newValue.y < -self.maxOffset) {
                                self.refreshPossible = YES;
                                [self startAnimating];
                            }
                            else {
                                self.refreshPossible = NO;
                                [self stopAnimating];
                            }
                        }

                        [UIView animateWithDuration:0 animations:^{
                            [self.superview layoutIfNeeded];
                        }];
                    }
                    else if (!self.refreshing) {
                        self.viewHeightConstraint.constant = 0;
                        self.hidden = YES;
                        [self stopRefreshing];
                    }

                }
                else {

                }
            }
        }
    }
}

- (void)changeAlphaAndRotation:(CGFloat)offset {

    if ([self.imageView.layer animationForKey:@"rotation"]) {
        return;
    }

    float value = offset / self.maxOffset;

    self.imageView.alpha = value;
}

- (void)startAnimating {
    if ([self.imageView.layer animationForKey:@"rotation"]) {
        return;
    }

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.toValue = @(M_PI * 2.0f);
    animation.duration = 0.75;
    animation.removedOnCompletion = NO;
    animation.cumulative = YES;
    animation.repeatCount = HUGE;

    [self.imageView.layer addAnimation:animation forKey:@"rotation"];
}

- (void)stopAnimating {
    [self.imageView.layer removeAllAnimations];
}

- (void)startRefreshing {
    if (!self.refreshPossible) {
        return;
    }

    self.refreshing = YES;
    self.refreshPossible = NO;

    BOOL bouncePreviousValue = self.scrollView.bounces;
    self.scrollView.bounces = NO;

    if (self.direction == NHRefreshViewDirectionTop) {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             UIEdgeInsets inset = self.scrollView.contentInset;
                             inset.top = 80;
                             self.scrollView.contentInset = inset;
                             [self.superview layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             self.scrollView.bounces = bouncePreviousValue;
                         }];
    }
    else {

    }

    [self performRefresh];
}

- (void)stopRefreshing {
    if (!self.refreshing
        && !self.refreshPossible) {
        return;
    }

    self.refreshPossible = NO;
    self.refreshing = NO;

    if (self.direction == NHRefreshViewDirectionTop) {
        if (self.scrollView.contentInset.top == 0) {
            return;
        }
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             UIEdgeInsets inset = self.scrollView.contentInset;
                             inset.top = 0;
                             self.scrollView.contentInset = inset;
                             [self.superview layoutIfNeeded];
                             self.hidden = NO;
                         } completion:^(BOOL finished) {
                             self.hidden = YES;
                             [self stopAnimating];
                         }];
    }
    else {
        
    }
}

- (void)performRefresh {
    NSLog(@"refresh");
    __weak __typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf stopRefreshing];
    });
}

- (void)dealloc {
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
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
