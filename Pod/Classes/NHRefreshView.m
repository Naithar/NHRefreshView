//
//  NHRefreshView.m
//  Pods
//
//  Created by Naithar on 05.05.15.
//
//

#import "NHRefreshView.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) \
([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface NHRefreshView ()

@property (nonatomic, weak) UIScrollView *scrollView;

@property (nonatomic, assign) NHRefreshViewDirection direction;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSLayoutConstraint *viewVerticalConstraint;
@property (nonatomic, strong) NSLayoutConstraint *viewHeightConstraint;

@property (nonatomic, assign) BOOL refreshPossible;
@property (nonatomic, assign) BOOL refreshing;

@property (nonatomic, assign) UIEdgeInsets refreshViewInsets;

@property (nonatomic, assign) NSTimeInterval refreshTimestamp;

@end

@implementation NHRefreshView

- (instancetype)initWithScrollView:(UIScrollView*)scrollView {
    return [self initWithScrollView:scrollView
                       refreshBlock:nil];
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView
                      refreshBlock:(NHRefreshBlock)refreshBlock {
    return [self initWithScrollView:scrollView
                          direction:NHRefreshViewDirectionTop
                       refreshBlock:refreshBlock];
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView
                         direction:(NHRefreshViewDirection)direction {
    return [self initWithScrollView:scrollView
                          direction:direction
                       refreshBlock:nil];
}

- (instancetype)initWithScrollView:(UIScrollView*)scrollView
                         direction:(NHRefreshViewDirection)direction
                      refreshBlock:(NHRefreshBlock)refreshBlock {
    self = [super init];

    if (self) {
        _scrollView = scrollView;
        _direction = direction;
        _refreshBlock = refreshBlock;
        [self commonInit];
    }

    return self;
}

- (void)commonInit {

    _delayValue = 0.5;
    _maxOffset = 100;
    _refreshOffset = 80;
    _animationDuration = 0.75;
    _initialScrollViewInsets = self.scrollView.contentInset;
    _refreshViewInsets = UIEdgeInsetsZero;

    self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.containerView.opaque = YES;
    self.containerView.backgroundColor = self.scrollView.backgroundColor;
    [self.containerView setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.scrollView.subviews.firstObject addSubview:self.containerView];

    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.scrollView.subviews.firstObject
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1.0 constant:0]];

    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.scrollView.subviews.firstObject
                                                                attribute:NSLayoutAttributeWidth
                                                               multiplier:1.0
                                                                 constant:0]];

    if (self.direction == NHRefreshViewDirectionTop) {
        self.viewVerticalConstraint = [NSLayoutConstraint constraintWithItem:self.containerView
                                                                   attribute: NSLayoutAttributeBottom
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.scrollView.subviews.firstObject
                                                                   attribute:NSLayoutAttributeTop
                                                                  multiplier:1.0 constant:0];
    }
    else {
        self.viewVerticalConstraint = [NSLayoutConstraint constraintWithItem:self.containerView
                                                                   attribute: NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.scrollView.subviews.firstObject
                                                                   attribute:NSLayoutAttributeTop
                                                                  multiplier:1.0
                                                                    constant:MAX(
                                                                                 self.scrollView.bounds.size.height - self.initialScrollViewInsets.bottom,
                                                                                 self.scrollView.contentSize.height)];
    }

    [self.scrollView addConstraint:self.viewVerticalConstraint];

    self.viewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.containerView
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.containerView
                                                             attribute:NSLayoutAttributeHeight
                                                            multiplier:0
                                                              constant:0];

    [self.containerView addConstraint:self.viewHeightConstraint];



    self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.imageView.opaque = YES;
    self.imageView.image = [UIImage imageNamed:@"NHRefreshView.loading.png"];
    self.imageView.contentMode = UIViewContentModeCenter;
    self.imageView.backgroundColor = self.scrollView.backgroundColor;
    [self.imageView setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.containerView addSubview:self.imageView];

    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.containerView
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0 constant:0]];

    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.containerView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0 constant:0]];

    [self.scrollView setNeedsUpdateConstraints];
    [self.scrollView setNeedsLayout];

    [self.scrollView addObserver:self
                      forKeyPath:@"contentOffset"
                         options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                         context:nil];

    [self.scrollView addObserver:self
                      forKeyPath:@"contentSize"
                         options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                         context:nil];

    [self.scrollView addObserver:self
                      forKeyPath:@"bounds"
                         options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                         context:nil];

    [self.scrollView addObserver:self
                      forKeyPath:@"backgroundColor"
                         options:NSKeyValueObservingOptionNew
                         context:nil];

    [self.scrollView.panGestureRecognizer addTarget:self action:@selector(panGestureAction:)];
    self.containerView.hidden = YES;
    self.containerView.clipsToBounds = YES;
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
                CGFloat offset = 0;

                if (self.direction == NHRefreshViewDirectionTop) {
                    offset = (-newValue.y) - self.initialScrollViewInsets.top;
                }
                else {
                    if (self.scrollView.bounds.size.height > self.scrollView.contentSize.height) {
                        offset = newValue.y - MAX(0, self.scrollView.contentSize.height - (self.scrollView.bounds.size.height - self.initialScrollViewInsets.bottom));
                    }
                    else {
                        offset = self.scrollView.bounds.size.height
                        + newValue.y
                        - self.scrollView.contentSize.height
                        - self.initialScrollViewInsets.bottom;
                    }
                    //                : (self.scrollView.bounds.size.height + self.scrollView.contentOffset.y + (self.scrollView.bounds.size.height > self.scrollView.contentSize.height ? self.initialScrollViewInsets.bottom : 0)) - MAX(self.scrollView.contentSize.height, self.scrollView.bounds.size.height) - self.initialScrollViewInsets.bottom;
                }

                if (offset > 0) {
                    self.viewHeightConstraint.constant = MAX(offset, self.refreshing ? self.refreshOffset : 0);
                    self.containerView.hidden = NO;

                    if (!self.refreshing) {
                        [self changeAlphaAndRotation:offset];

                        if (offset > self.maxOffset) {
                            self.refreshPossible = YES;
                            [self startAnimating];
                        }
                        else {
                            self.refreshPossible = NO;
                            [self stopAnimating];
                        }
                    }

                    [UIView animateWithDuration:0 animations:^{
                        [self.containerView.superview layoutIfNeeded];
                    }];
                }
                else if (!self.refreshing) {
                    self.viewHeightConstraint.constant = 0;
                    self.containerView.hidden = YES;
                    [self stopRefreshing];
                }
            }
        }
        else if ([keyPath isEqualToString:@"contentSize"]
                 && self.direction == NHRefreshViewDirectionBottom) {
            CGSize oldValue = [change[NSKeyValueChangeOldKey] CGSizeValue];
            CGSize newValue = [change[NSKeyValueChangeNewKey] CGSizeValue];

            if (!CGSizeEqualToSize(oldValue, newValue)) {
                self.viewVerticalConstraint.constant = MAX(newValue.height, self.scrollView.bounds.size.height - self.initialScrollViewInsets.bottom);
                [self.containerView.superview layoutIfNeeded];
            }
        }
        else if ([keyPath isEqualToString:@"bounds"]
                 && self.direction == NHRefreshViewDirectionBottom) {
            CGRect oldValue = [change[NSKeyValueChangeOldKey] CGRectValue];
            CGRect newValue = [change[NSKeyValueChangeNewKey] CGRectValue];

            if (!CGRectEqualToRect(oldValue, newValue)) {
                self.viewVerticalConstraint.constant = MAX(newValue.size.height - self.initialScrollViewInsets.bottom, self.scrollView.contentSize.height);

                [self.containerView.superview layoutIfNeeded];
            }
        }
        else if ([keyPath isEqualToString:@"backgroundColor"]) {
            UIColor *newValue = change[NSKeyValueChangeNewKey];

            self.containerView.backgroundColor = newValue;
            self.imageView.backgroundColor = newValue;
        }
    }
}

- (void)changeAlphaAndRotation:(CGFloat)offset {

    if ([self.imageView.layer animationForKey:@"rotation"]) {
        return;
    }

    float value = offset / self.maxOffset;

    self.imageView.alpha = value;

    CGFloat anglePart = value * M_PI * 2;
    self.imageView.transform = CGAffineTransformMakeRotation(anglePart);
}

- (void)startAnimating {
    if ([self.imageView.layer animationForKey:@"rotation"]) {
        return;
    }

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.toValue = @(M_PI * 2.0f);
    animation.duration = _animationDuration;
    animation.removedOnCompletion = NO;
    animation.cumulative = YES;
    animation.repeatCount = HUGE;

    self.imageView.transform = CGAffineTransformMakeRotation(0);
    [self.imageView.layer addAnimation:animation forKey:@"rotation"];
}

- (void)stopAnimating {
    [self.imageView.layer removeAllAnimations];
}

- (void)setInitialScrollViewInsets:(UIEdgeInsets)initialScrollViewInsets {
    if (UIEdgeInsetsEqualToEdgeInsets(_initialScrollViewInsets, initialScrollViewInsets)) {
        return;
    }

    [self willChangeValueForKey:@"initialScrollViewInsets"];
    _initialScrollViewInsets = initialScrollViewInsets;


    self.viewVerticalConstraint.constant = MAX(self.scrollView.bounds.size.height - self.initialScrollViewInsets.bottom, self.scrollView.contentSize.height);
    [self.containerView.superview layoutIfNeeded];

    [self didChangeValueForKey:@"initialScrollViewInsets"];
}

- (void)startRefreshing {
    if (!self.refreshPossible) {
        return;
    }

    self.refreshing = YES;
    self.refreshPossible = NO;

    BOOL bouncePreviousValue = self.scrollView.bounces;

    if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        self.scrollView.bounces = NO;
    }

    UIEdgeInsets insets = self.scrollView.contentInset;
    self.refreshViewInsets = UIEdgeInsetsMake((self.direction == NHRefreshViewDirectionTop)
                                              ? self.refreshOffset
                                              : 0, 0,
                                              (self.direction == NHRefreshViewDirectionBottom)
                                              ? MAX(self.refreshOffset,
                                                    self.scrollView.bounds.size.height
                                                    - self.initialScrollViewInsets.bottom
                                                    - self.scrollView.contentSize.height
                                                    + self.refreshOffset)
                                              : 0, 0);

    BOOL refreshValue = YES;
    __weak __typeof(self) weakSelf = self;

    if ([weakSelf.delegate respondsToSelector:@selector(refreshView:shouldChangeInsetsForScrollView:withValue:)]) {
        refreshValue = [weakSelf.delegate refreshView:weakSelf
                      shouldChangeInsetsForScrollView:weakSelf.scrollView
                                            withValue:weakSelf.refreshViewInsets];
    }

    if (!refreshValue) {
        self.scrollView.bounces = bouncePreviousValue;
        [self performRefresh];
        return;
    }

    if (self.direction == NHRefreshViewDirectionTop) {
        insets.top = self.initialScrollViewInsets.top + self.refreshViewInsets.top;
    }
    else {
        insets.bottom = self.initialScrollViewInsets.bottom + self.refreshViewInsets.bottom;
    }

    //max(scrollView.bounds.height - scrollView.contentSize.height + self.loadingOffset, self.originalBottomInset + self.loadingOffset)

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = insets;
                         [self.containerView.superview layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         self.scrollView.bounces = bouncePreviousValue;
                         [self performRefresh];
                     }];
}

- (void)stopRefreshing {
    if (!self.refreshing
        && !self.refreshPossible) {
        return;
    }

    self.refreshPossible = NO;
    self.refreshing = NO;

    if ((self.direction == NHRefreshViewDirectionTop
         && self.scrollView.contentInset.top == self.initialScrollViewInsets.top)
        || (self.direction == NHRefreshViewDirectionBottom
            && self.scrollView.contentInset.bottom == self.initialScrollViewInsets.bottom)) {
            return;
        }

    BOOL refreshValue = YES;
    __weak __typeof(self) weakSelf = self;

    if ([weakSelf.delegate respondsToSelector:@selector(refreshView:shouldChangeInsetsForScrollView:withValue:)]) {
        refreshValue = [weakSelf.delegate refreshView:weakSelf
                      shouldChangeInsetsForScrollView:weakSelf.scrollView
                                            withValue:UIEdgeInsetsZero];
    }

    if (!refreshValue) {
        return;
    }

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         UIEdgeInsets newInsets = self.scrollView.contentInset;
                         if (self.direction == NHRefreshViewDirectionTop) {
                             newInsets.top = self.initialScrollViewInsets.top;
                         }
                         else {
                             newInsets.bottom = self.initialScrollViewInsets.bottom;
                         }

                         self.scrollView.contentInset = newInsets;
                         [self.containerView.superview layoutIfNeeded];
                         self.containerView.hidden = NO;
                     } completion:^(BOOL finished) {
                         self.containerView.hidden = YES;
                         [self stopAnimating];
                     }];
}

- (void)performRefresh {

    self.refreshTimestamp = [[NSDate date] timeIntervalSince1970];

    NSTimeInterval refreshTimestamp = self.refreshTimestamp;

    if (self.refreshBlock) {
        __weak __typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delayValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;

            if (strongSelf.refreshTimestamp != refreshTimestamp) {
                return;
            }

            strongSelf.refreshBlock();
        });
    }
}

- (void)dealloc {
    self.refreshBlock = nil;
    [self.containerView removeFromSuperview];
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [self.scrollView removeObserver:self forKeyPath:@"contentSize"];
    [self.scrollView removeObserver:self forKeyPath:@"backgroundColor"];
    [self.scrollView removeObserver:self forKeyPath:@"bounds"];
}

@end
