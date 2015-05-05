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

@interface NHRefreshView : UIView

@property (nonatomic, readonly, weak) UIScrollView *scrollView;
@property (nonatomic, readonly, strong) UIImageView *imageView;

@property (nonatomic, assign) CGFloat maxOffset;

@property (nonatomic, readonly, assign) NHRefreshViewDirection direction;

- (instancetype)initWithScrollView:(UIScrollView*)scrollView;
- (instancetype)initWithScrollView:(UIScrollView*)scrollView
                         direction:(NHRefreshViewDirection)direction;
@end
