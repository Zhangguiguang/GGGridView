//
//  GGGridView.m
//  GGGridView
//
//  Created by 张贵广 on 2021/01/23.
//

#import "GGGridView.h"
#import <Masonry/Masonry.h>

struct GGGrid {
    NSInteger row;
    NSInteger column;
};
typedef struct GGGrid GGGrid;

UIKIT_STATIC_INLINE GGGrid GGGridMake(NSInteger row, NSInteger column) {
    GGGrid grid;
    grid.row = row; grid.column = column;
    return grid;
}


@interface GGGridView ()

/// 所有被表格管理的子视图
@property (nonatomic, strong) NSMutableArray<__kindof UIView *> *gridSubviews;

/// 列布局参照
@property (nonatomic, strong) UIStackView *columnGuideView;

/// 行布局参照
@property (nonatomic, strong) UIStackView *rowGuideView;

@property (nonatomic, strong) NSMapTable<NSNumber *, UIView *> *rowSeparators;
@property (nonatomic, strong) NSMapTable<NSNumber *, UIView *> *columnSeparators;

@end

@implementation GGGridView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _gridSubviews = [NSMutableArray new];
        _columnGuideView = [UIStackView new];
        _columnGuideView.axis = UILayoutConstraintAxisHorizontal;
        _rowGuideView = [UIStackView new];
        _rowGuideView.axis = UILayoutConstraintAxisVertical;
        
        [self addSubview:_columnGuideView];
        [self addSubview:_rowGuideView];
        
        self.contentInset = UIEdgeInsetsZero;
        self.numberOfColumns = 3;
        self.columnSpacing = 10;
        self.rowSpacing = 10;
    }
    return self;
}

- (void)dealloc {
    [_gridSubviews removeAllObjects];
}

- (void)willRemoveSubview:(UIView *)subview {
    [self p_removeGridSubView:subview];
    [super willRemoveSubview:subview];
}

- (void)p_removeGridSubView:(UIView *)view {
    if (![_gridSubviews containsObject:view]) {
        return;
    }
    
    NSInteger idx = [_gridSubviews indexOfObject:view];
    [_gridSubviews removeObject:view];
    [self _adjustGuidView:_rowGuideView capacity:self.numberOfRows];
    [self _updateGridLayoutFromIndex:idx];
    [self _adjustAllRowSeparators];
}

#pragma mark - Public Function

- (void)addGridSubview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [_gridSubviews addObject:view];
    [self addSubview:view];
    
    [self _adjustGuidView:_rowGuideView capacity:self.numberOfRows];
    [self _layoutGridView:view atIndex:_gridSubviews.count-1];
    [self _updateRowSeparatorLayoutAtIndex:self.numberOfRows - 1];
}

- (void)removeGridSubview:(UIView *)view {
    [view removeFromSuperview];
}

- (void)setCustomSpacing:(CGFloat)spacing afterColumn:(NSInteger)column {
    UIView *anchor = _columnGuideView.arrangedSubviews[column]; // 下标越界的考虑，请调用者处理
    [_columnGuideView setCustomSpacing:spacing afterView:anchor];
    [self _updateColumnSeparatorLayoutAtIndex:column + 1];
}

- (void)setCustomSpacing:(CGFloat)spacing afterRow:(NSInteger)row {
    UIView *anchor = _rowGuideView.arrangedSubviews[row]; // 下标...
    [_rowGuideView setCustomSpacing:spacing afterView:anchor];
    [self _updateRowSeparatorLayoutAtIndex:row + 1];
}

- (UIView *)gridSubviewAtRow:(NSInteger)row column:(NSInteger)column {
    NSInteger index = [self _indexOfGrid:GGGridMake(row, column)];
    return _gridSubviews[index]; // 下标...
}

- (NSLayoutDimension *)widthAnchorAtColumn:(NSUInteger)column {
    return _columnGuideView.arrangedSubviews[column].widthAnchor; // 下标...
}

- (NSLayoutDimension *)heightAnchorAtRow:(NSUInteger)row {
    return _rowGuideView.arrangedSubviews[row].heightAnchor; // 下标...
}

- (void)animationLayoutWithDuration:(NSTimeInterval)duration
                         completion:(void (^)(BOOL finished))completion {
    [UIView animateWithDuration:duration animations:^{
        [self.superview layoutIfNeeded];
    } completion:completion];
}

- (UIView *)rowSeparatorAtIndex:(NSInteger)index {
    UIView *separator = [_rowSeparators objectForKey:@(index)];
    if (!separator) {
        separator = [self _newRowSeparator];
        [self.rowSeparators setObject:separator forKey:@(index)];
        
        [self _updateRowSeparatorLayoutAtIndex:index];
    }
    return separator;
}

- (UIView *)columnSeparatorAtIndex:(NSInteger)index {
    UIView *separator = [_columnSeparators objectForKey:@(index)];
    if (!separator) {
        separator = [self _newColumnSeparator];
        [self.columnSeparators setObject:separator forKey:@(index)];
        
        [self _updateColumnSeparatorLayoutAtIndex:index];
    }
    return separator;
}

#pragma mark - Setter Getter
- (void)setNumberOfColumns:(NSInteger)numberOfColumn {
    NSInteger oldNumberOfColumn = self.numberOfColumns;
    if (oldNumberOfColumn == numberOfColumn) return;
    
    [self _adjustGuidView:_columnGuideView capacity:numberOfColumn];
    [self _adjustGuidView:_rowGuideView capacity:self.numberOfRows];
    [self _updateGridLayoutFromIndex:MIN(numberOfColumn, oldNumberOfColumn)];
    [self _adjustAllRowSeparators];
    [self _adjustAllColumnSeparators];
}

- (NSInteger)numberOfColumns {
    return _columnGuideView.arrangedSubviews.count;
}

- (NSInteger)numberOfRows {
    return (NSInteger)ceil(1.0 * _gridSubviews.count / _columnGuideView.arrangedSubviews.count);
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    _contentInset = contentInset;
    
    [_columnGuideView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(@(contentInset.left));
        make.trailing.lessThanOrEqualTo(@(-contentInset.right));
        make.top.equalTo(self);
        make.height.equalTo(@0);
    }];
    [_rowGuideView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(contentInset.top));
        make.bottom.lessThanOrEqualTo(@(-contentInset.bottom));
        make.leading.equalTo(self);
        make.width.equalTo(@0);
    }];
}

- (void)setColumnSpacing:(CGFloat)columnSpacing {
    if (_columnGuideView.spacing == columnSpacing) return;
    _columnGuideView.spacing = columnSpacing;
    [_columnSeparators.keyEnumerator.allObjects enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        [self _updateColumnSeparatorLayoutAtIndex:obj.integerValue];
    }];
}
- (CGFloat)columnSpacing {
    return _columnGuideView.spacing;
}

- (void)setRowSpacing:(CGFloat)rowSpacing {
    if (_rowGuideView.spacing == rowSpacing) return;
    _rowGuideView.spacing = rowSpacing;
    [_rowSeparators.keyEnumerator.allObjects enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        [self _updateRowSeparatorLayoutAtIndex:obj.integerValue];
    }];
}
- (CGFloat)rowSpacing {
    return _rowGuideView.spacing;
}

#pragma mark - Lazy Load

- (NSMapTable<NSNumber *,UIView *> *)rowSeparators {
    if (!_rowSeparators) {
        _rowSeparators = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                               valueOptions:NSPointerFunctionsWeakMemory];
    }
    return _rowSeparators;
}

- (NSMapTable<NSNumber *,UIView *> *)columnSeparators {
    if (!_columnSeparators) {
        _columnSeparators = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                  valueOptions:NSPointerFunctionsWeakMemory];
    }
    return _columnSeparators;
}

#pragma mark - Helper

/// 调整参照容器的大小
- (void)_adjustGuidView:(UIStackView *)guideView capacity:(NSInteger)capacity {
    NSArray *arrangedViews = guideView.arrangedSubviews;
    NSInteger currentCapacity = arrangedViews.count;
    if (currentCapacity > capacity) {
        for (NSInteger idx = capacity; idx < currentCapacity; idx++) {
            UIView *temp = arrangedViews[idx];
            [temp removeFromSuperview];
        }
    } else if (currentCapacity < capacity) {
        for (NSInteger idx = 0; idx < capacity - currentCapacity; idx++) {
            UIView *temp = [UIView new];
            [guideView addArrangedSubview:temp];
        }
    }
}

/// 给指定位置的子视图布局
- (void)_layoutGridView:(UIView *)view atIndex:(NSInteger)index {
    GGGrid grid = [self _gridAtIndex:index];
    UIView *columnGuide = _columnGuideView.arrangedSubviews[grid.column];
    UIView *rowGuide = _rowGuideView.arrangedSubviews[grid.row];
    [view mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(columnGuide);
        make.trailing.lessThanOrEqualTo(columnGuide);
        make.top.equalTo(rowGuide);
        make.bottom.lessThanOrEqualTo(rowGuide);
    }];
}

/// 更新所有子视图的布局
/// @param index 从 index 开始，对它以及后面的视图重新布局， 可以认为 index 前面的视图，位置是没有变动的。
- (void)_updateGridLayoutFromIndex:(NSInteger)index {
    NSInteger count = _gridSubviews.count;
    for (NSInteger idx = index; idx < count; idx++) {
        [self _layoutGridView:_gridSubviews[idx] atIndex:idx];
    }
}

- (GGGrid)_gridAtIndex:(NSInteger)index {
    return GGGridMake((NSInteger)(index / self.numberOfColumns),
                      (NSInteger)(index % self.numberOfColumns));
}

- (NSInteger)_indexOfGrid:(GGGrid)grid {
    return grid.row * self.numberOfColumns + grid.column;
}

- (UIView *)_newRowSeparator {
    UIView *separator = [UIView new];
    separator.backgroundColor = [UIColor lightGrayColor];
    separator.userInteractionEnabled = NO;
    [self addSubview:separator];
    
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    [separator gg_heighEqualTo:1 priority:UILayoutPriorityFittingSizeLevel];
    [separator.leadingAnchor constraintEqualToAnchor:self.columnGuideView.leadingAnchor].active = YES;
    [separator.trailingAnchor constraintEqualToAnchor:self.columnGuideView.trailingAnchor].active = YES;
    return separator;
}

- (void)_updateRowSeparatorLayoutAtIndex:(NSInteger)index {
    UIView *separator = [_rowSeparators objectForKey:@(index)];
    if (!separator) {
        return;
    }
    
    [separator mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (index == 0) {
            make.centerY.lessThanOrEqualTo(self.rowGuideView.mas_top);
        } else if (index >= self.numberOfRows) {
            make.centerY.greaterThanOrEqualTo(self.rowGuideView.mas_bottom);
        } else {
            UIView *preView = self.rowGuideView.arrangedSubviews[index - 1];
            CGFloat spacing = [self.rowGuideView customSpacingAfterView:preView];
            if (spacing == UIStackViewSpacingUseDefault) {
                spacing = self.rowSpacing;
            }
            
            make.centerY.equalTo(preView.mas_bottom).offset(spacing / 2);
        }
    }];
}

- (UIView *)_newColumnSeparator {
    UIView *separator = [UIView new];
    separator.backgroundColor = [UIColor lightGrayColor];
    separator.userInteractionEnabled = NO;
    [self addSubview:separator];
    
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    [separator gg_widthEqualTo:1 priority:UILayoutPriorityFittingSizeLevel];
    [separator.topAnchor constraintEqualToAnchor:self.rowGuideView.topAnchor].active = YES;
    [separator.bottomAnchor constraintEqualToAnchor:self.rowGuideView.bottomAnchor].active = YES;
    return separator;
}

- (void)_updateColumnSeparatorLayoutAtIndex:(NSInteger)index {
    UIView *separator = [_columnSeparators objectForKey:@(index)];
    if (!separator) {
        return;
    }
    
    [separator mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (index == 0) {
            make.centerX.lessThanOrEqualTo(self.columnGuideView.mas_leading);
        } else if (index >= self.numberOfColumns) {
            make.centerX.greaterThanOrEqualTo(self.columnGuideView.mas_trailing);
        } else {
            UIView *preView = self.columnGuideView.arrangedSubviews[index - 1];
            CGFloat spacing = [self.columnGuideView customSpacingAfterView:preView];
            if (spacing == UIStackViewSpacingUseDefault) {
                spacing = self.columnSpacing;
            }
            make.centerX.equalTo(preView.mas_trailing).offset(spacing / 2);
        }
    }];
}

/// 调整分割线数量
- (void)_adjustAllRowSeparators {
    NSInteger numberOfRows = self.numberOfRows;
    [_rowSeparators.keyEnumerator.allObjects enumerateObjectsUsingBlock:^(NSNumber *key, NSUInteger _, BOOL *stop) {
        NSInteger rowIndex = key.integerValue;
        if (rowIndex == numberOfRows || rowIndex == numberOfRows - 1) {
            // 最后两条分割线，可能是需要被调整的
            [self _updateRowSeparatorLayoutAtIndex:rowIndex];
        } else if (rowIndex > numberOfRows) {
            // 会删掉多余的线
            [[_rowSeparators objectForKey:key] removeFromSuperview];
            [_rowSeparators removeObjectForKey:key];
        }
    }];
}

/// 调整分割线数量
- (void)_adjustAllColumnSeparators {
    NSInteger numberOfColumns = self.numberOfColumns;
    [_columnSeparators.keyEnumerator.allObjects enumerateObjectsUsingBlock:^(NSNumber *key, NSUInteger _, BOOL *stop) {
        NSInteger columnIndex = key.integerValue;
        if (columnIndex == numberOfColumns || columnIndex == numberOfColumns - 1) {
            // 最后两条分割线，可能是需要被调整的
            [self _updateColumnSeparatorLayoutAtIndex:columnIndex];
        } else if (columnIndex > numberOfColumns) {
            // 会删掉多余的线
            [[_columnSeparators objectForKey:key] removeFromSuperview];
            [_columnSeparators removeObjectForKey:key];
        }
    }];
}

@end



@implementation UIView (GGGridView)

- (void)gg_widthEqualTo:(CGFloat)width {
    [self _dimension:self.widthAnchor equalTo:width priority:UILayoutPriorityDefaultHigh];
}
- (void)gg_widthEqualTo:(CGFloat)width priority:(UILayoutPriority)priority {
    [self _dimension:self.widthAnchor equalTo:width priority:priority];
}

- (void)gg_heighEqualTo:(CGFloat)height {
    [self _dimension:self.heightAnchor equalTo:height priority:UILayoutPriorityDefaultHigh];
}
- (void)gg_heighEqualTo:(CGFloat)height priority:(UILayoutPriority)priority {
    [self _dimension:self.heightAnchor equalTo:height priority:priority];
}

- (void)_dimension:(NSLayoutDimension *)dimension
           equalTo:(CGFloat)constant
          priority:(UILayoutPriority)priority {
    NSLayoutConstraint *temp = [dimension constraintEqualToConstant:constant];
    temp.priority = priority;
    temp.active = YES;
}

@end
