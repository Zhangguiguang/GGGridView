//
//  GGGridView.h
//  GGGridView
//
//  Created by 张贵广 on 2021/01/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 支持行列对齐的网格视图
@interface GGGridView : UIView

/// 添加一个被表格管理的 view
/// @discussion view 应该自己管理宽高，但是当你想调整某一整行或一整列的宽高时，约束可能会有冲突
/// 因此应该让 view 宽高的约束优先级必须小于 UILayoutPriorityRequired
/// @note Masonry 单独添加宽高约束，似乎要必须先添加到父视图才有效。并且配合该组件使用也有些奇怪的问题
/// 因此不太建议使用 Masonry, 可以使用 UIView+GGGridView 分类的功能
- (void)addGridSubview:(UIView *)view;

/// 完全的移除掉一个表格元素
/// @discussion 也可以使用 [view removeFromSuperview] 来达到同样的效果
- (void)removeGridSubview:(UIView *)view;

/// 列数 default 3
@property (nonatomic, assign) NSInteger numberOfColumns;

/// 行数，是计算属性
@property (nonatomic, readonly) NSInteger numberOfRows;

/// 内边距 default .Zero
@property (nonatomic, assign) UIEdgeInsets contentInset;

/// 元素之间水平的间距 default 10
@property (nonatomic, assign) CGFloat columnSpacing;

/// 元素之间垂直的间距 default 10
@property (nonatomic, assign) CGFloat rowSpacing;

/// 单独调整第 column 列后边的间距
- (void)setCustomSpacing:(CGFloat)spacing afterColumn:(NSInteger)column;

/// 单独调整第 row 行底下的间距
- (void)setCustomSpacing:(CGFloat)spacing afterRow:(NSInteger)row;

/// 获取指定位置的子视图
- (UIView *)gridSubviewAtRow:(NSInteger)row column:(NSInteger)column;

/// 获取第 column 列的宽度锚
/// @discussion 可以通过这种方式，调整指定列的宽度约束
- (NSLayoutDimension *)widthAnchorAtColumn:(NSUInteger)column;

/// 获取第 row 行的高度锚
/// @discussion 可以通过这种方式，调整指定行的高度约束
- (NSLayoutDimension *)heightAnchorAtRow:(NSUInteger)row;

/// 对列表的所有改动，都是可动画的
/// 该方法可以表现布局改动的动画过程
- (void)animationLayoutWithDuration:(NSTimeInterval)duration
                         completion:(void (^ __nullable)(BOOL finished))completion;

/// 获取横向的分割线，默认 lightGray, 1 pt
/// @param index  ∈ [0, numberOfRows] 分割线会比行数多 1
/// @discussion 分割线默认不显示，但是当你调用该方法时，它就会创建并显示
- (UIView *)rowSeparatorAtIndex:(NSInteger)index;

/// 获取纵向的分割线，默认 black N7, 1 px
/// @param index  ∈ [0, numberOfColumns] 分割线会比列数多 1
/// @discussion 分割线默认不显示，但是当你调用该方法时，它就会创建并显示
- (UIView *)columnSeparatorAtIndex:(NSInteger)index;

#pragma mark - Plan
// 待支持

/// 添加一个空的占位元素
//- (void)addEmptyGridSubview;

/// 列对齐方式
//@property (nonatomic, assign) GGGridPlacement xPlacement;
/// 行对齐方式
//@property (nonatomic, assign) GGGridPlacement yPlacement;
/// 指定行的对齐方式
//- (void)setCustomPlacement:(GGGridPlacement)placement atRow:(NSInteger)row;
/// 指定列的对齐方式
//- (void)setCustomPlacement:(GGGridPlacement)placement atColumn:(NSInteger)column;

@end


@interface UIView (GGGridView)

- (void)gg_widthEqualTo:(CGFloat)width;
- (void)gg_widthEqualTo:(CGFloat)width priority:(UILayoutPriority)priority;

- (void)gg_heighEqualTo:(CGFloat)height;
- (void)gg_heighEqualTo:(CGFloat)height priority:(UILayoutPriority)priority;

@end

NS_ASSUME_NONNULL_END
