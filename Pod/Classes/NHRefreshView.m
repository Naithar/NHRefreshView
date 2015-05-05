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

@property (nonatomic, assign) UIEdgeInsets refreshViewInsets;
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
    self = [super initWithFrame:CGRectZero];

    if (self) {
        _scrollView = scrollView;
        _direction = direction;
        _refreshBlock = refreshBlock;
        [self commonInit];
    }

    return self;
}

- (void)commonInit {

    _maxOffset = 100;
    _refreshOffset = 80;
    _animationDuration = 0.75;
    _initialScrollViewInsets = self.scrollView.contentInset;
    _refreshViewInsets = UIEdgeInsetsZero;

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
    animation.duration = _animationDuration;
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

    UIEdgeInsets insets = self.initialScrollViewInsets;
    self.refreshViewInsets = UIEdgeInsetsMake((self.direction == NHRefreshViewDirectionTop)
                                              ? self.refreshOffset
                                              : 0, 0,
                                              (self.direction == NHRefreshViewDirectionBottom)
                                              ? self.refreshOffset
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
        return;
    }

    insets.top += self.refreshViewInsets.top;
    insets.bottom += self.refreshViewInsets.bottom;

    if (self.direction == NHRefreshViewDirectionTop) {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.scrollView.contentInset = insets;
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

    if (self.direction == NHRefreshViewDirectionTop) {
        if (self.scrollView.contentInset.top == 0) {
            return;
        }

        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.scrollView.contentInset = self.initialScrollViewInsets;
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
    if (self.refreshBlock) {
        self.refreshBlock();
    }
}

- (void)dealloc {
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

@end
