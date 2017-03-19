//
//  ZGLoopScrollView.m
//  ZGLoopScrollView
//
//  ZGLoopScrollView.h
//  ZGLoopScrollView
//
//  Created by Droid on 17/3/19.
//  Copyright © 2017年 ZengGen. All rights reserved.
//

#import "ZGLoopScrollView.h"

/**
 *  动画所用常量
 */
CFTimeInterval const kLongPressDuration = 0.5;      //长按触发事件
CFTimeInterval const kDelecerateDution = 0.2;
CFTimeInterval const kBounceDution = 0.4;
CFTimeInterval const kScrollDution = 0.4;
CFTimeInterval const kAutoScrollDefaultDution = 5.0;
CFTimeInterval const kAutoScrollMinDution = kScrollDution + 0.1;

CGFloat const kDelecerateMinMove = 0.000001;
CGFloat const kDelecerateMinVelocity = 100;
CGFloat const kBounceFactor = 0.8;

@interface ZGLoopScrollView ()
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSMutableDictionary *itemViews;
@property (nonatomic, strong) NSMutableSet *itemViewPool;

@property (nonatomic, assign) CGFloat itemWith;
@property (nonatomic, assign) CGFloat scrollOffset;
@property (nonatomic, assign) CGFloat lastTranslation;

@property (nonatomic, assign) CGFloat delecerateStartTime;
@property (nonatomic, assign) CGFloat delecerateStartVelocity;
@property (nonatomic, assign) CGFloat delecerateAcceleration;
@property (nonatomic, assign) CGFloat delecerateStartOffset;
@property (nonatomic, assign) CGFloat delecerateDistance;

@property (nonatomic, assign) CGFloat bounceStartTime;
@property (nonatomic, assign) CGFloat bounceStopVelocity;
@property (nonatomic, assign) CGFloat bounceateAcceleration;
@property (nonatomic, assign) CGFloat bounceStartOffset;
@property (nonatomic, assign) CGFloat bounceDistance;

@property (nonatomic, assign) CGFloat scrollStartTime;
@property (nonatomic, assign) CGFloat scrollVelocity;
@property (nonatomic, assign) CGFloat scrollStartOffset;
@property (nonatomic, assign) CGFloat scrollDistance;

@property (nonatomic, assign) NSInteger itemsCount;
@property (nonatomic, assign) NSInteger visibleItemsCount;
@property (nonatomic, assign) NSInteger currentItemIndex;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) NSTimer *autoScrollTimer;


@property (nonatomic, assign) BOOL scrolling;
@property (nonatomic, assign) BOOL draging;
@property (nonatomic, assign) BOOL decelerating;
@property (nonatomic, assign) BOOL bouncing;

@end

@implementation ZGLoopScrollView

#pragma mark- initView
#pragma mark-
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self initView];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame{
    if ((self = [super initWithFrame:frame]))
    {
        [self initView];
    }
    return self;
}

- (void)dealloc
{
    
}


- (void)setDataSource:(id<ZGLoopScrollViewDataSource>)dataSource
{
    if (_dataSource != dataSource)
    {
        _dataSource = dataSource;
        if (_dataSource)
        {
            [self reloadData];
        }
    }
}

- (void)initView{
    _contentView = [[UIView alloc] init];
    _contentView.clipsToBounds = YES;
    [self addSubview:_contentView];
    [_contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *contraint1 = [NSLayoutConstraint constraintWithItem:_contentView
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1.0
                                                                   constant:1.0];
    NSLayoutConstraint *contraint2 = [NSLayoutConstraint constraintWithItem:_contentView
                                                                  attribute:NSLayoutAttributeLeft
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self
                                                                  attribute:NSLayoutAttributeLeft
                                                                 multiplier:1.0
                                                                   constant:1.0];
    
    NSLayoutConstraint *contraint3 = [NSLayoutConstraint constraintWithItem:_contentView
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1.0
                                                                   constant:-1.0];
    
    NSLayoutConstraint *contraint4 = [NSLayoutConstraint constraintWithItem:_contentView
                                                                  attribute:NSLayoutAttributeRight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self
                                                                  attribute:NSLayoutAttributeRight
                                                                 multiplier:1.0
                                                                   constant:-1.0];
    NSArray *array = [NSArray arrayWithObjects:contraint1, contraint2, contraint3, contraint4,  nil];
    
    [self addConstraints:array];
    
    
    //add pan gesture recogniser
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanGesture:)];
    panGesture.delegate = (id <UIGestureRecognizerDelegate>)self;
    [_contentView addGestureRecognizer:panGesture];
    
    //add tap gesture recogniser
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapGesture:)];
    tapGesture.delegate = (id <UIGestureRecognizerDelegate>)self;
    [_contentView addGestureRecognizer:tapGesture];
    
    //add tap gesture recogniser
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressGesture:)];
    longPressGesture.delegate = (id <UIGestureRecognizerDelegate>)self;
    longPressGesture.minimumPressDuration = kLongPressDuration;
    [_contentView addGestureRecognizer:longPressGesture];
    
    //set up accessibility
    self.accessibilityTraits = UIAccessibilityTraitAllowsDirectInteraction;
    self.isAccessibilityElement = YES;
    _autoScrollDution = kAutoScrollDefaultDution;
//    _vertical = YES;
    _bounceEnabled = YES;
    _loopEnabled = YES;
//    self.pageEnabled = YES;
//    _contentView.backgroundColor = [UIColor lightGrayColor];//-----------------------
    
    if (_dataSource)
    {
        [self reloadData];
    }
    NSLog(@"%@",NSStringFromCGRect(_contentView.frame));
}



- (void)reloadData{
    for (UIView *view in [_itemViews allValues])
    {
        [view.superview removeFromSuperview];
    }
    
    if (!_dataSource || !_contentView)
    {
        return;
    }
    _visibleItemsCount = 0;
    _itemsCount = [_dataSource countOfItemsInLoopScrollView:self];
    self.itemViews = [NSMutableDictionary dictionary];
    self.itemViewPool = [NSMutableSet set];
    _itemWith = _vertical ? self.bounds.size.height: self.bounds.size.width;
    [self loadView];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _contentView.frame = self.bounds;
}



#pragma mark- UIGestureRecognizer Delegate Medoth
-(void)didPanGesture:(UIPanGestureRecognizer *)panGesture{

        switch (panGesture.state)
        {
            case UIGestureRecognizerStateBegan:
            {
                [self stopAutoScrollTimer];
                _draging = YES;
                _bouncing = NO;
                _decelerating = NO;
                _scrolling = NO;
                _lastTranslation = - _vertical? [panGesture translationInView:self].y: [panGesture translationInView:self].x;
                if([_delegate respondsToSelector:@selector(loopScrollViewWillBeginDragging:)])
                    [_delegate loopScrollViewWillBeginDragging:self];
                break;
            }
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateCancelled:
            case UIGestureRecognizerStateFailed:
            {
                if(ABS(_delecerateStartVelocity) < kDelecerateMinVelocity){
                    if([_delegate respondsToSelector:@selector(loopScrollViewDidEndDragging:willDecelerate:)])
                        [_delegate loopScrollViewDidEndDragging:self willDecelerate:NO];
                    [self didBounce];
                }else{
                    if([_delegate respondsToSelector:@selector(loopScrollViewDidEndDragging:willDecelerate:)])
                        [_delegate loopScrollViewDidEndDragging:self willDecelerate:YES];
                    _delecerateAcceleration = - _delecerateStartVelocity / kDelecerateDution;
                    _delecerateStartTime = CACurrentMediaTime();
                    _delecerateDistance = - 0.5 * _delecerateStartVelocity * kDelecerateDution;
                    _delecerateStartOffset = _scrollOffset;
                    _decelerating = YES;
                    if([_delegate respondsToSelector:@selector(loopScrollViewWillBeginDecelerating:)])
                        [_delegate loopScrollViewWillBeginDecelerating:self];
                    [self startScrollAnimation];
                }
                [self setAutoScrollEnabled:_autoScrollEnabled];
                break;
            }
            case UIGestureRecognizerStateChanged:
            {
                CGFloat translation = _vertical? [panGesture translationInView:self].y: [panGesture translationInView:self].x;
                CGFloat velocity = _vertical? [panGesture velocityInView:self].y: [panGesture velocityInView:self].x;
                translation = -translation;
                velocity = -velocity;
                CGFloat moveDistance = translation - _lastTranslation;
                [self didScroll:moveDistance];
                _lastTranslation = translation;
                _delecerateStartVelocity = velocity;
//                NSLog(@"%f,%f",translation,velocity);
                break;
            }
            case UIGestureRecognizerStatePossible:
            {
                //do nothing
                break;
            }
        }


}


-(void)didTapGesture:(UITapGestureRecognizer *)tapGesture{
    if([_delegate respondsToSelector:@selector(loopScrollView:didSelectItemAtIndex:)]){
        NSInteger index = [self itemIndexAtTouchPoint:[tapGesture locationInView:_contentView]];
        if (index != NSNotFound)
            [_delegate loopScrollView:self didSelectItemAtIndex:index];
        else
            [_delegate loopScrollView:self didSelectItemAtIndex:self.currentItemIndex];
    }
}


-(void)didLongPressGesture:(UILongPressGestureRecognizer *)longPressGesture{
    if(longPressGesture.state == UIGestureRecognizerStateBegan){
        if([_delegate respondsToSelector:@selector(loopScrollView:didLongPressItemAtIndex:)]){
            NSInteger index = [self itemIndexAtTouchPoint:[longPressGesture locationInView:_contentView]];
            if (index != NSNotFound)
                [_delegate loopScrollView:self didLongPressItemAtIndex:index];
            else
                [_delegate loopScrollView:self didLongPressItemAtIndex:self.currentItemIndex];
        }
    }
}

-(NSInteger)itemIndexAtTouchPoint:(CGPoint) point{
    for (NSNumber *idx in [_itemViews allKeys]) {
        UIView *view = _itemViews[idx];
        if ([view.superview.layer hitTest:point])
            return [idx integerValue];
    }
    return NSNotFound;
}



#pragma mark- View Queuing
- (void)queueItemView:(UIView *)view
{
    if (view)
    {
        [_itemViewPool addObject:view];
    }
}

- (UIView *)dequeueItemView
{
    UIView *view = [_itemViewPool anyObject];
    if (view)
    {
        [_itemViewPool removeObject:view];
    }
    return view;
}

#pragma mark- Load View Medoth
-(void)loadView{
    CGFloat width = _itemWith;
    _visibleItemsCount = ceil(width / _itemWith) + 2;
    if(!_loopEnabled)
        _visibleItemsCount = MAX(0, MIN(_visibleItemsCount, _itemsCount));
    NSMutableSet *visibleIndices = [NSMutableSet setWithCapacity:_visibleItemsCount];
    NSInteger min = _bounceEnabled ? - kBounceFactor : 0;
    NSInteger max = _itemsCount - 1 - min;
    NSInteger offsetIdx = self.currentItemIndex - _visibleItemsCount/2;
    if (!_loopEnabled && !_bounceEnabled)
    {
        offsetIdx = MAX(min, MIN(max - _visibleItemsCount + 1, offsetIdx));
    }
    for (NSInteger i = 0; i < _visibleItemsCount; i++)
    {
        NSInteger index = i + offsetIdx;
        [visibleIndices addObject:@(index)];

    }
    
    for (NSNumber *number in [_itemViews allKeys])
    {
        if (![visibleIndices containsObject:number])
        {
            UIView *view = _itemViews[number];
            [self queueItemView:view];
            [view.superview removeFromSuperview];
            [(NSMutableDictionary *)_itemViews removeObjectForKey:number];
        }
    }
    
    for (NSNumber *number in visibleIndices)
    {
        UIView *view = _itemViews[number];
        NSInteger index = [number integerValue];
        if(!_loopEnabled && (index < 0 || index > _itemsCount - 1))
            continue;
        if(_itemsCount < 1)
            continue;
        if (view == nil)
        {
            view = [self loadViewAtIndex:index];
        }
        CGFloat offset = index* width - _scrollOffset;
        CATransform3D transform = CATransform3DIdentity;
        transform = _vertical ?  CATransform3DTranslate(transform, 0.0, offset, 0.0) :
        CATransform3DTranslate(transform, offset  , 0.0, 0.0);
        view.superview.layer.transform = transform;
    }

}

- (UIView *)loadViewAtIndex:(NSInteger)index
{
    UIView *view = [_dataSource loopScrollView:self viewForItemAtIndex:(index + _itemsCount)%_itemsCount reusingView:[self dequeueItemView]];
    if (view == nil)
    {
        view = [[UIView alloc] init];
    }
    _itemViews[@(index)] = view;
    CGRect frame = self.bounds;
    UIView *containerView = [[UIView alloc] initWithFrame:frame];
    view.center = containerView.center;
    [containerView addSubview:view];
    [_contentView addSubview:containerView];
    return view;
}



#pragma mark- Animation Medoth
-(void)startScrollAnimation{
    if(_displayLink == nil){
        self.displayLink=[CADisplayLink displayLinkWithTarget:self selector:@selector(scrollAnimation)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}
-(void)stopScrollAnimation{
    if(_displayLink){
        @try {
            [_displayLink invalidate];
            self.displayLink = nil;
        } @catch (NSException *exception) {
            
        }
    }
}

-(void)scrollAnimation{
    CFTimeInterval currentTime = CACurrentMediaTime();
    if(_decelerating){
        CGFloat t = currentTime - _delecerateStartTime;
        if(t > kDelecerateDution){
            _decelerating = NO;
            [self didBounce];
        }else{
            CGFloat a = _delecerateAcceleration;
            CGFloat v = _delecerateStartVelocity;
            CGFloat s = v * t + a * t * t / 2;
            CGFloat offSet = _delecerateStartOffset  + s;
            CGFloat moveDistance = offSet - _scrollOffset;
            [self didScroll:moveDistance];
        }
    
    }else if(_bouncing){
        CGFloat t = currentTime - _bounceStartTime;
        if(t > kBounceDution){
            _bouncing = NO;
            [self stopScrollAnimation];
            CGFloat offSet;
            offSet = _scrollOffset <  _itemWith * (_itemsCount-1) / 2 ? 0 : _itemWith * (_itemsCount-1);
            CGFloat moveDistance = offSet - _scrollOffset;
            [self didScroll:moveDistance];
            if([_delegate respondsToSelector:@selector(loopScrollViewDidEndBouncing:atTop:)])
                [_delegate loopScrollViewDidEndBouncing:self atTop:_scrollOffset <= 0];

        }else{
            CGFloat a = _bounceateAcceleration;
            CGFloat s = a * t * t / 2;
            CGFloat offSet = _bounceStartOffset  + s;
            CGFloat moveDistance = offSet - _scrollOffset;
            [self didScroll:moveDistance];
        }
    } else if(_scrolling){
        CGFloat t = currentTime - _scrollStartTime;
        if(t > kScrollDution){
            _scrolling = NO;
            [self stopScrollAnimation];
            CGFloat offSet = _scrollStartOffset + _scrollDistance;
            CGFloat moveDistance = offSet - _scrollOffset;
            [self didScroll:moveDistance];
            if([_delegate respondsToSelector:@selector(loopScrollViewDidEndScroll:toIndex:)])
                [_delegate loopScrollViewDidEndScroll:self toIndex:_scrollOffset / _itemWith];
            
        }else{
            CGFloat s = _scrollVelocity * t;
            CGFloat offSet = _scrollStartOffset  + s;
            CGFloat moveDistance = offSet - _scrollOffset;
            [self didScroll:moveDistance];
        }
    }
    
}


-(void)didBounce{
    if(_pageEnabled){
        [self scrollToIndex:round(_scrollOffset / _itemWith) animated:YES];
    }else if(_bounceEnabled && (!_loopEnabled && (_scrollOffset < 0 || _scrollOffset > _itemWith*(_itemsCount-1)))){
        _bouncing = YES;
        _bounceStartTime = CACurrentMediaTime();
        _bounceStartOffset = _scrollOffset;
        _bounceDistance = _scrollOffset < 0 ? - _scrollOffset : _itemWith*(_itemsCount-1) - _scrollOffset;
        _bounceateAcceleration = 2 * _bounceDistance / pow(kBounceDution, 2);
        _bounceStopVelocity = _bounceateAcceleration * kBounceDution;
        [self startScrollAnimation];
        if([_delegate respondsToSelector:@selector(loopScrollViewWillBeginBouncing:atTop:)])
            [_delegate loopScrollViewWillBeginBouncing:self atTop:_scrollOffset < 0];
    }else{
        [self stopScrollAnimation];
    }
}

-(void)didScroll:(CGFloat)moveDistance{
    BOOL isMoveLeft = moveDistance < 0;
    CGFloat offSet = _scrollOffset + moveDistance;
    if(!_loopEnabled ){
        if(!_bounceEnabled){
            if(offSet < 0)
                _scrollOffset = 0;
            else if(offSet > _itemWith*(_itemsCount-1))
                _scrollOffset = _itemWith*(_itemsCount-1);
            else
                _scrollOffset = offSet;
        }else{
            if(_scrollOffset < 0 && isMoveLeft){
                CGFloat bounceMoveDistance = - (1 + _scrollOffset / (kBounceFactor * _itemWith)) * moveDistance/2;
                CGFloat limitMoveDistance = kBounceFactor * _itemWith + _scrollOffset;
                _scrollOffset += - MIN(limitMoveDistance / 4, bounceMoveDistance);
            }
            else if(_scrollOffset > _itemWith*(_itemsCount-1) && !isMoveLeft){
                CGFloat bounceMoveDistance = (1 - (_scrollOffset-_itemWith*(_itemsCount-1)) / (kBounceFactor * _itemWith)) * moveDistance;
                CGFloat limitMoveDistance = _itemWith*(_itemsCount-1) + kBounceFactor * _itemWith - _scrollOffset;
                _scrollOffset +=  MIN(limitMoveDistance / 4, bounceMoveDistance/2);
            }else{
                _scrollOffset = offSet;
            }
        }
    }else{
        if(offSet < -(_itemWith*(_visibleItemsCount/2)))
            _scrollOffset = offSet + _itemWith * (_itemsCount);
        else if(offSet > _itemWith*(_itemsCount-1 + _visibleItemsCount/2))
            _scrollOffset = offSet - _itemWith * (_itemsCount);
        else
            _scrollOffset = offSet;
        
    }
    [self loadView];
    
    if([_delegate respondsToSelector:@selector(loopScrollViewDidScroll:)])
        [_delegate loopScrollViewDidScroll:self];
}



#pragma mark- AutoScroll Medoth

-(void)startAutoScrollTimer{
    if (self.autoScrollTimer == nil){
        self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:MAX(_autoScrollDution, kAutoScrollMinDution)
                                                                target:self
                                                              selector:@selector(didScrollToNextPage)
                                                              userInfo:nil
                                                               repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.autoScrollTimer forMode:NSRunLoopCommonModes];
    }
}
-(void)stopAutoScrollTimer{
    @try {
        if (self.autoScrollTimer) {
            [self.autoScrollTimer invalidate];
            self.autoScrollTimer = nil;
        }
    } @catch (NSException *exception) {
    }
}


-(void)didScrollToNextPage{
    NSInteger index = self.currentItemIndex + (_autoScrollNegative ? -1: 1);
    [self scrollToIndex:index animated:YES];
}



#pragma mark- Public Medoth

-(void)setAutoScrollDution:(CGFloat)autoScrollDution{
    _autoScrollDution = autoScrollDution;
    [self stopAutoScrollTimer];
    [self setAutoScrollEnabled:_autoScrollEnabled];
}

//设置scrollView是否可以自动滚动.
- (void)setAutoScrollEnabled:(BOOL)autoScrollEnabled{
    _autoScrollEnabled = autoScrollEnabled;
    if (autoScrollEnabled)
        [self startAutoScrollTimer];
    else
        [self stopAutoScrollTimer];
}


-(NSInteger)currentItemIndex{
    _currentItemIndex = round(_scrollOffset / _itemWith);
    return _currentItemIndex;
}

- (UIView *)itemViewAtIndex:(NSInteger)index{
    UIView *view = _itemViews[@(index)];
    if (view == nil)
    {
        view =[self loadViewAtIndex:index];
    }
    
    return view;
}
- (NSInteger)indexOfItemView:(UIView *)view{
    for (NSNumber *numb in [_itemViews allKeys]) {
        if(view == _itemViews[numb])
            return [numb integerValue];
    }
    return NSNotFound;
}

-(void)scrollToIndex:(NSInteger)index animated:(BOOL) animated{
//    NSInteger realIdx = index;
//    if(_loopEnabled){
//        while (realIdx < 0)
//            realIdx += _itemsCount;
//        realIdx %= _itemsCount;
//    }else{
//        if(index < 0)
//            realIdx = 0;
//        else if(index > _itemsCount - 1)
//            realIdx = _itemsCount - 1;
//    
//    }
    
    if(!animated){
        [self didScroll:_itemWith - _scrollOffset];
    }else{
        _scrolling = YES;
        _scrollStartTime = CACurrentMediaTime();
        _scrollStartOffset = _scrollOffset;
        _scrollDistance =  _itemWith * index - _scrollOffset;
        _scrollVelocity = _scrollDistance / kScrollDution;
        [self startScrollAnimation];
        if([_delegate respondsToSelector:@selector(loopScrollViewWillBeginScroll:fromIndex:)])
        [_delegate loopScrollViewWillBeginScroll:self fromIndex:round(_scrollOffset / _itemWith)];
    }
}



@end
