//
//  GGViewController.m
//  GGGridView
//
//  Created by zhangguiguang on 01/23/2021.
//  Copyright (c) 2021 zhangguiguang. All rights reserved.
//

#import "GGViewController.h"
#import <GGGridView/GGGridView.h>
#import <Masonry/Masonry.h>

@interface GGViewController ()
@property (nonatomic, strong) GGGridView *gridView;

@property (nonatomic, strong) GGGridView *gridView2;

@end

@implementation GGViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _test1];
    [self _test2];
}

- (void)_test1 {
    NSInteger step = 5;
    
    _gridView = [GGGridView new];
    _gridView.numberOfColumns = step;
    _gridView.rowSpacing = 20;
    _gridView.columnSpacing = 15;

    for (NSInteger row=1; row<=step; row++) {
        for (NSInteger column=1; column<=step; column++) {
            if (column <= row) {
                NSString *formular = [NSString stringWithFormat:@"%ldx%ld=%ld", row, column, row*column];
                [_gridView addGridSubview:[self viewWithText:formular]];
            } else {
                [_gridView addGridSubview:[UIView new]];
            }
        }
    }
    
    [[_gridView columnSeparatorAtIndex:1] gg_widthEqualTo:3];
    [[_gridView rowSeparatorAtIndex:4] gg_heighEqualTo:3];
    
    [_gridView columnSeparatorAtIndex:4];
    [_gridView rowSeparatorAtIndex:1];
    
    [_gridView rowSeparatorAtIndex:4].backgroundColor = [UIColor blueColor];
    [_gridView rowSeparatorAtIndex:1].backgroundColor = [UIColor redColor];
    
    [self.view addSubview:_gridView];
    [_gridView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(@30);
        make.top.equalTo(@100);
    }];
}

- (void)_test2 {
    NSArray<NSArray *> *temp = @[
        @[@"Discover", @"iOS", @"iPadOS", @"macOS", @"tvOS", @"watchOS", @"Safari and Web", @"Games", @"Business", @"Education", @"WWDC"],
        @[@"Design", @"Human Interface Guidelines", @"Resources", @"Videos", @"Apple Design Awards", @"Fonts", @"Accessibility", @"Localization", @"Accessories"],
        @[@"Develop", @"Xcode", @"Swift", @"Swift Playgrounds", @"TestFlight", @"Documentation", @"Videos", @"Downloads"],
        @[@"Distribute", @"Developer Program", @"App Store", @"App Review", @"Mac Software", @"Apps for Business", @"Safari Extensions", @"Marketing Resources", @"Trademark Licensing"],
        @[@"Support",@"Articles",@"Developer Forums",@"Feedback & Bug Reporting",@"System Status",@"Contact Us"],
    ];

    NSInteger columns = temp.count;
    __block NSInteger rows = 0;
    [temp enumerateObjectsUsingBlock:^(NSArray *obj, NSUInteger idx, BOOL *stop) {
        if (obj.count > rows) {
            rows = obj.count;
        }
    }];
    
    _gridView2 = [GGGridView new];
    _gridView2.numberOfColumns = columns;
    _gridView2.columnSpacing = 6;
    
    for (NSInteger row=0; row<rows; row++) {
        for (NSInteger column=0; column<columns; column++) {
            NSArray *sub = temp[column];
            if (sub.count > row) {
                UILabel *label = [self viewWithText:sub[row]];
                if (row == 0) {
                    label.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
                } else {
                    label.font = [UIFont systemFontOfSize:10];
                }
                [_gridView2 addGridSubview:label];
            } else {
                [_gridView2 addGridSubview:[UIView new]];
            }
        }
    }
    
    for (NSInteger column=0; column<columns; column++) {
        [[_gridView2 widthAnchorAtColumn:column] constraintEqualToAnchor:_gridView2.widthAnchor multiplier:(1.0 / columns) constant:-(columns-1)*_gridView2.columnSpacing/columns].active = YES;
    }
    
    [self.view addSubview:_gridView2];
    [_gridView2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(@10);
        make.trailing.lessThanOrEqualTo(@-10);
        make.bottom.lessThanOrEqualTo(@-60);
    }];
}

- (UILabel *)viewWithText:(NSString *)text {
    UILabel *label = [UILabel new];
    label.text = text;
    return label;
}

@end
