//
//  ZGLoopScrollView.h
//  ZGLoopScrollView
//
//  Created by Droid on 17/3/19.
//  Copyright © 2017年 ZengGen. All rights reserved.
//


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZGLoopScrollViewDataSource, ZGLoopScrollViewDelegate;

@interface ZGLoopScrollView : UIView
@property (nonatomic, weak) IBOutlet __nullable id<ZGLoopScrollViewDataSource> dataSource;
@property (nonatomic, weak) IBOutlet __nullable id<ZGLoopScrollViewDelegate> delegate;


@property (nonatomic, assign, getter = isAutoScrollEnabled ) BOOL autoScrollEnabled;
/**
 direction to scroll default is NO
 */
@property (nonatomic, assign, getter = isAutoScrollNegative) BOOL autoScrollNegative;
/**
 vertical or Horizontal scroll default is NO
 */
@property (nonatomic, assign, getter = isVertical          ) BOOL vertical;
@property (nonatomic, readonly, getter = isScrolling       ) BOOL scrolling;
@property (nonatomic, assign, getter = isLoopEnabled       ) BOOL loopEnabled;
@property (nonatomic, assign, getter = isBounceEnabled     ) BOOL bounceEnabled;
@property (nonatomic, assign, getter = isPageEnabled       ) BOOL pageEnabled;

@property (nonatomic, setter = setAutoScrollDution:) CGFloat autoScrollDution;


- (void)reloadData;
- (UIView *)itemViewAtIndex:(NSInteger)index;
- (NSInteger)indexOfItemView:(UIView *)view;
- (void)scrollToIndex:(NSInteger)index animated:(BOOL) animated;
@end

@protocol ZGLoopScrollViewDataSource <NSObject>
@required
- (NSInteger)countOfItemsInLoopScrollView:(ZGLoopScrollView *)loopScrollView;
- (UIView *)loopScrollView:(ZGLoopScrollView *)loopScrollView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view;
@end

@protocol ZGLoopScrollViewDelegate <NSObject>
@optional
- (void)loopScrollView:(ZGLoopScrollView *)loopScrollView didSelectItemAtIndex:(NSInteger)index;
- (void)loopScrollView:(ZGLoopScrollView *)loopScrollView didLongPressItemAtIndex:(NSInteger)index;
- (void)loopScrollViewDidScroll:(ZGLoopScrollView *)loopScrollView; // any offset changes
// called on start of dragging (may require some time and or distance to move)
- (void)loopScrollViewWillBeginDragging:(ZGLoopScrollView *)loopScrollView;
// called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
- (void)loopScrollViewDidEndDragging:(ZGLoopScrollView *)loopScrollView willDecelerate:(BOOL)decelerate;
- (void)loopScrollViewWillBeginDecelerating:(ZGLoopScrollView *)loopScrollView;   // called on finger up as we are moving
- (void)loopScrollViewDidEndDecelerating:(ZGLoopScrollView *)loopScrollView;      // called when scroll view grinds to a halt
- (void)loopScrollViewWillBeginBouncing:(ZGLoopScrollView *)loopScrollView atTop:(BOOL) isTop; // called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
- (void)loopScrollViewDidEndBouncing:(ZGLoopScrollView *)loopScrollView atTop:(BOOL) isTop;  // called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
- (void)loopScrollViewWillBeginScroll:(ZGLoopScrollView *)loopScrollView fromIndex:(NSInteger) index; // called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
- (void)loopScrollViewDidEndScroll:(ZGLoopScrollView *)loopScrollView toIndex:(NSInteger) index;  // called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
@end
NS_ASSUME_NONNULL_END
