//
//  ViewController.m
//  ZGLoopScrollViewDemo
//
//  Created by Droid on 17/3/19.
//  Copyright © 2017年 ZengGen. All rights reserved.
//


#import "ViewController.h"
#import "ZGLoopScrollView.h"

#define UIColorFromHex(s)  [UIColor colorWithRed:(((s & 0xFF0000) >> 16))/255.0 green:(((s &0xFF00) >>8))/255.0 blue:((s &0xFF))/255.0 alpha:1.0]


@interface Model : NSObject
@property (nonatomic, copy) NSString *index;
@property (nonatomic) UIColor *color;
@end

@implementation Model

@end

@interface ViewController ()<ZGLoopScrollViewDataSource,ZGLoopScrollViewDelegate>
@property (weak, nonatomic) IBOutlet ZGLoopScrollView *loopScrollView;
@property (strong, nonatomic) NSMutableArray<Model *> *items;
@end

@implementation ViewController
    
- (void)viewDidLoad {
    [super viewDidLoad];
    _loopScrollView.dataSource = self;
    _loopScrollView.delegate = self;
//    _loopScrollView.autoScrollEnabled = YES;
//    _loopScrollView.bounceEnabled = NO;
    _loopScrollView.autoScrollDution = 1;
    _loopScrollView.pageEnabled = YES;
    self.items = [NSMutableArray array];
    for (int i = 0; i < 2; i++)
    {
        Model *model = [Model new];
        model.color = [self randomColor];
        model.index = @(i).stringValue;
        [_items addObject:model];
    }
    [_loopScrollView reloadData];
}
    
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [_loopScrollView reloadData];
}
    
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
    
-(UIColor *)randomColor{
    int c;
    c = arc4random() % 0x1000000;
    return UIColorFromHex(c);
}
    
-(NSInteger)countOfItemsInLoopScrollView:(ZGLoopScrollView *)loopScrollView{
    return _items.count;
    
}
    
-(UIView *)loopScrollView:(ZGLoopScrollView *)loopScrollView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    UILabel *label = nil;
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        view = [[UIView alloc] initWithFrame:loopScrollView.frame];
        view.contentMode = UIViewContentModeCenter;
//        view.backgroundColor = [self randomColor];
        label = [[UILabel alloc] initWithFrame:view.bounds];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [label.font fontWithSize:50];
        label.tag = 1;
        [view addSubview:label];
    }
    else
    {
        label = (UILabel *)[view viewWithTag:1];
    }
    label.text = _items[index].index;
    view.backgroundColor = _items[index].color;
    return view;
}
    
-(void)loopScrollView:(ZGLoopScrollView *)loopScrollView didSelectItemAtIndex:(NSInteger)index{
    NSLog(@"select %ld", (long)index);
}
    
    
-(void)loopScrollView:(ZGLoopScrollView *)loopScrollView didLongPressItemAtIndex:(NSInteger)index{
    NSLog(@"longpress %ld", (long)index);
}
    
    
    
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [_loopScrollView reloadData];
    
}

@end
