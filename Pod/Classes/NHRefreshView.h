//
//  NHRefreshView.h
//  Pods
//
//  Created by Naithar on 05.05.15.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, NHRefreshViewDirection) {
    NHRefreshViewDirectionTop,
    NHRefreshViewDirectionBottom,
};



@class NHRefreshView;

typedef void(^NHRefreshBlock)(void);

@protocol NHRefreshViewDelegate <NSObject>

@optional
- (BOOL)refreshView:(NHRefreshView*)refreshView shouldChangeInsetsForScrollView:(UIScrollView*)scrollView withValue:(UIEdgeInsets)refreshViewInsets;

@end

@interface NHRefreshView : NSObject

@property (nonatomic, weak) id<NHRefreshViewDelegate> delegate;

@property (nonatomic, readonly, weak) UIScrollView *scrollView;
@property (nonatomic, readonly, strong) UIView *containerView;
@property (nonatomic, readonly, strong) UIImageView *imageView;

@property (nonatomic, assign) CGFloat maxOffset;
@property (nonatomic, assign) CGFloat refreshOffset;
@property (nonatomic, readonly, assign) NHRefreshViewDirection direction;

@property (nonatomic, copy) NHRefreshBlock refreshBlock;

@property (nonatomic, assign) UIEdgeInsets initialScrollViewInsets;
@property (nonatomic, readonly, assign) UIEdgeInsets refreshViewInsets;

@property (nonatomic, assign) float animationDuration;

- (instancetype)initWithScrollView:(UIScrollView*)scrollView;
- (instancetype)initWithScrollView:(UIScrollView*)scrollView
                      refreshBlock:(NHRefreshBlock)refreshBlock;

- (instancetype)initWithScrollView:(UIScrollView*)scrollView
                         direction:(NHRefreshViewDirection)direction;
- (instancetype)initWithScrollView:(UIScrollView*)scrollView
                         direction:(NHRefreshViewDirection)direction
                      refreshBlock:(NHRefreshBlock)refreshBlock;


- (void)stopRefreshing;
@end
