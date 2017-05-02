//
//  SCNavTabBar.m
//  SCNavTabBarController
//
//  Created by ShiCang on 14/11/17.
//  Copyright (c) 2014年 SCNavTabBarController. All rights reserved.
//

#import "SCNavTabBar.h"
#import "CommonMacro.h"
#import "SCPopView.h"

@interface SCNavTabBar () <SCPopViewDelegate>
{
    UIScrollView    *_navgationTabBar;      // all items on this scroll view
    UIImageView     *_arrowButton;          // arrow button
    
    UIView          *_line;                 // underscore show which item selected
    UIView          *_bottomDivider;
    SCPopView       *_popView;              // when item menu, will show this view
    
    NSMutableArray  *_items;                // SCNavTabBar pressed item
    NSArray         *_itemsWidth;           // an array of items' width
    BOOL            _canPopAllItemMenu;     // is showed arrow button
    BOOL            _popItemMenu;           // is needed pop item menu
    
    UILabel         *_tipsView;             // show tips
}

@end

@implementation SCNavTabBar

- (id)initWithFrame:(CGRect)frame canPopAllItemMenu:(BOOL)can
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _buttonShadowColor = [UIColor lightGrayColor];
        _buttonShadowRadius = 4.0f;
        _buttonShadowOpacity = 1.0f;
        _buttonShadowOffset = CGSizeMake(0, -5);
        
        _canPopAllItemMenu = can;
        [self initConfig];
    }
    return self;
}

#pragma mark -
#pragma mark - Private Methods

- (void)initConfig
{
    _items = [@[] mutableCopy];
    _arrowImage = [UIImage imageNamed:SCNavTabbarSourceName(@"arrow.png")];
    
    [self viewConfig];
    [self addTapGestureRecognizer];
}

- (CGFloat)tabsShowWidth
{
    return _canPopAllItemMenu ? (SCREEN_WIDTH - ARROW_BUTTON_WIDTH) : SCREEN_WIDTH;
}

- (void)viewConfig
{
    if (_canPopAllItemMenu)
    {
        _arrowButton = [[UIImageView alloc] initWithFrame:CGRectMake([self tabsShowWidth], DOT_COORDINATE, ARROW_BUTTON_WIDTH, ARROW_BUTTON_WIDTH)];
        _arrowButton.image = _arrowImage;
        _arrowButton.userInteractionEnabled = YES;
        [self addSubview:_arrowButton];
        _arrowButton.layer.shadowColor = _buttonShadowColor.CGColor;
        _arrowButton.layer.shadowRadius = _buttonShadowRadius;
        _arrowButton.layer.shadowOpacity = _buttonShadowOpacity;
        _arrowButton.layer.shadowOffset = _buttonShadowOffset;
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(functionButtonPressed)];
        [_arrowButton addGestureRecognizer:tapGestureRecognizer];
    }

    _navgationTabBar = [[UIScrollView alloc] initWithFrame:CGRectMake(DOT_COORDINATE, DOT_COORDINATE, [self tabsShowWidth], NAV_TAB_BAR_HEIGHT)];
    _navgationTabBar.showsHorizontalScrollIndicator = NO;
    [self addSubview:_navgationTabBar];
    
    // nav下面加一条分割线
    CGFloat lineSize = 1.0 / [UIScreen mainScreen].scale;
    _bottomDivider = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height-lineSize, self.frame.size.width, lineSize)];
    _bottomDivider.backgroundColor = [UIColor colorWithRed:0.867 green:0.867 blue:0.867 alpha:1.0];
    [self addSubview:_bottomDivider];
    
    // 添加一个tipsView(点击分类可直接跳转)
    _tipsView = [[UILabel alloc] initWithFrame:CGRectMake(18, 16, 100, 20)];
    _tipsView.text = @"点击分类可直接跳转";
    _tipsView.font = [UIFont systemFontOfSize:12.0f];
    _tipsView.textColor = [UIColor colorWithRed:0.631 green:0.631 blue:0.631 alpha:1.0];
    [_tipsView sizeToFit];
    _tipsView.hidden = YES;
    [self addSubview:_tipsView];
    //隐藏navBar底部阴影
//    [self viewShowShadow:self shadowRadius:4.0f shadowOpacity:10.0f];
}

- (void)showLineWithButtonWidth:(CGFloat)width
{
    _line = [[UIView alloc] initWithFrame:CGRectMake(2.0f, NAV_TAB_BAR_HEIGHT - 3.0f, width - 4.0f, 3.0f)];
    if (self.lineColor == nil) {
        self.lineColor = [UIColor blueColor];
    }
    _line.backgroundColor = self.lineColor;
    [_navgationTabBar addSubview:_line];
}

- (CGFloat)contentWidthAndAddNavTabBarItemsWithButtonsWidth:(NSArray *)widths
{
    CGFloat buttonX = DOT_COORDINATE;
    for (NSInteger index = 0; index < [_itemTitles count]; index++)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(buttonX, DOT_COORDINATE, [widths[index] floatValue], NAV_TAB_BAR_HEIGHT);
        [button setTitle:_itemTitles[index] forState:UIControlStateNormal];
        button.titleLabel.font = _titleFont;
        [button setTitleColor:_titleFontColor forState:UIControlStateNormal];
        [button addTarget:self action:@selector(itemPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_navgationTabBar addSubview:button];
        
        [_items addObject:button];
        buttonX += [widths[index] floatValue];
    }
    
    [self showLineWithButtonWidth:[widths[0] floatValue]];
    return buttonX;
}

- (void)addTapGestureRecognizer
{
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(functionButtonPressed)];
    [_arrowButton addGestureRecognizer:tapGestureRecognizer];
}

- (void)itemPressed:(UIButton *)button
{
    NSInteger index = [_items indexOfObject:button];
    [_delegate itemDidSelectedWithIndex:index];
}

- (void)functionButtonPressed
{
    _popItemMenu = !_popItemMenu;
    [_delegate shouldPopNavgationItemMenu:_popItemMenu height:[self popMenuHeight]];
}

- (NSArray *)getButtonsWidthWithTitles:(NSArray *)titles;
{
    NSMutableArray *widths = [@[] mutableCopy];
    
    for (NSString *title in titles)
    {
//        CGSize size = [title sizeWithFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
        CGSize size = [title sizeWithAttributes:
                       @{NSFontAttributeName: _titleFont}];
        CGSize adjustedSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
        NSNumber *width = [NSNumber numberWithFloat:adjustedSize.width + 40.0f];
        [widths addObject:width];
    }
    
    return widths;
}

- (void)viewShowShadow:(UIView *)view shadowRadius:(CGFloat)shadowRadius shadowOpacity:(CGFloat)shadowOpacity
{
    view.layer.shadowRadius = shadowRadius;
    view.layer.shadowOpacity = shadowOpacity;
}

- (CGFloat)popMenuHeight
{
    CGFloat buttonX = DOT_COORDINATE;
    CGFloat buttonY = ITEM_HEIGHT;
    CGFloat maxHeight = SCREEN_HEIGHT - STATUS_BAR_HEIGHT - NAVIGATION_BAR_HEIGHT - NAV_TAB_BAR_HEIGHT;
    for (NSInteger index = 0; index < [_itemsWidth count]; index++)
    {
        buttonX += [_itemsWidth[index] floatValue];
        
        @try {
            if ((buttonX + [_itemsWidth[index + 1] floatValue]) >= SCREEN_WIDTH)
            {
                buttonX = DOT_COORDINATE;
                buttonY += ITEM_HEIGHT;
            }
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            
        }
    }
    
    buttonY = (buttonY > maxHeight) ? maxHeight : buttonY;
    return buttonY;
}

- (void)popItemMenu:(BOOL)pop
{
    if (pop)
    {
        [self viewShowShadow:_arrowButton shadowRadius:DOT_COORDINATE shadowOpacity:DOT_COORDINATE];
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _navgationTabBar.hidden = YES;
            _tipsView.hidden = !_navgationTabBar.hidden;
            _arrowButton.transform = CGAffineTransformMakeRotation(M_PI/4);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1f animations:^{
                if (!_popView)
                {
                    _popView = [[SCPopView alloc] initWithFrame:CGRectMake(DOT_COORDINATE, NAVIGATION_BAR_HEIGHT, SCREEN_WIDTH, self.frame.size.height - NAVIGATION_BAR_HEIGHT)];
                    _popView.delegate = self;
                    _popView.titleFont = _titleFont;
                    _popView.titleFontColor = _titleFontColor;
                    _popView.itemNames = _itemTitles;
                    [self addSubview:_popView];
                }
                _popView.hidden = NO;
            }];
        }];
    }
    else
    {
        [UIView animateWithDuration:0.5f animations:^{
            _popView.hidden = !_popView.hidden;
            _tipsView.hidden = !_tipsView.hidden;
            _arrowButton.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            _navgationTabBar.hidden = !_navgationTabBar.hidden;
            _arrowButton.layer.shadowRadius = _buttonShadowRadius;
            _arrowButton.layer.shadowOpacity = _buttonShadowOpacity;
            _arrowButton.layer.shadowOffset = _buttonShadowOffset;
        }];
    }
}

- (void)changeTabBarToIndex:(NSInteger)newIndex fromIndex:(NSInteger)oldIndex{
    if(newIndex == oldIndex){
        return;
    }
    
    CGFloat minOffset = 0;
    
    UIButton *lastBtn = _items.lastObject;
    CGFloat maxOffset = (lastBtn.frame.origin.x + lastBtn.frame.size.width) - SCREEN_WIDTH + (_canPopAllItemMenu? ARROW_BUTTON_WIDTH : 0);
    
    UIButton *button = _items[newIndex];
    
    // max length is smaller than tabbar length
    if(maxOffset <= 0){
        [self doLineAnimation:button index:newIndex];
        return;
    }
    
    if(newIndex == 0){
        [_navgationTabBar setContentOffset:CGPointMake(minOffset, DOT_COORDINATE) animated:YES];
        [self doLineAnimation:button index:newIndex];
        return;
    }
    
    // is last
    if(newIndex == _itemTitles.count-1){
        [_navgationTabBar setContentOffset:CGPointMake(maxOffset, DOT_COORDINATE) animated:YES];
        [self doLineAnimation:button index:newIndex];
        return;
    }
    
    BOOL isForward = newIndex > oldIndex;
    NSInteger nextIndex = newIndex + (isForward? 1 : -1);
    UIButton *nextBtn = _items[nextIndex];
    
    CGFloat newOffset = (nextBtn.frame.origin.x + nextBtn.frame.size.width) - SCREEN_WIDTH + (_canPopAllItemMenu? ARROW_BUTTON_WIDTH : 0);
    if(!isForward){
        newOffset = nextBtn.frame.origin.x;
    }
    
    if(nextIndex != 0 && newIndex != _items.count-1){
        newOffset += (isForward? 40.0f : -40.0f);
    }
    
    if(newOffset < minOffset){
        newOffset = minOffset;
    }
    
    if(newOffset > maxOffset) {
        newOffset = maxOffset;
    }
    [_navgationTabBar setContentOffset:CGPointMake(newOffset, DOT_COORDINATE) animated:YES];
    [self doLineAnimation:button index:newIndex];
}

- (void)doLineAnimation:(UIButton *)button index:(NSInteger)index {
    [UIView animateWithDuration:0.2f animations:^{
        _line.frame = CGRectMake(button.frame.origin.x + 2.0f, _line.frame.origin.y, [_itemsWidth[index] floatValue] - 4.0f, _line.frame.size.height);
    }];
}

#pragma mark -
#pragma mark - Public Methods

- (void)setButtonShadowColor:(UIColor *)buttonShadowColor {
    _arrowButton.layer.shadowColor = buttonShadowColor.CGColor;
    _buttonShadowColor = buttonShadowColor;
}

- (void)setButtonShadowRadius:(CGFloat)buttonShadowRadius {
    _arrowButton.layer.shadowRadius = buttonShadowRadius;
    _buttonShadowRadius = buttonShadowRadius;
}

- (void)setButtonShadowOpacity:(CGFloat)buttonShadowOpacity {
    _arrowButton.layer.shadowOpacity = buttonShadowOpacity;
    _buttonShadowOpacity = buttonShadowOpacity;
}

- (void)setButtonShadowOffset:(CGSize)buttonShadowOffset {
    _arrowButton.layer.shadowOffset = buttonShadowOffset;
    _buttonShadowOffset = buttonShadowOffset;
}

- (void)setArrowImage:(UIImage *)arrowImage
{
    _arrowImage = arrowImage ? arrowImage : _arrowImage;
    _arrowButton.image = _arrowImage;
}

- (void)setDividerColor:(UIColor *)dividerColor
{
    _dividerColor = dividerColor ? dividerColor : [UIColor colorWithRed:0.867 green:0.867 blue:0.867 alpha:1.0];
    _bottomDivider.backgroundColor = _dividerColor;
}

- (void)setCurrentItemIndex:(NSInteger)currentItemIndex
{
    [self changeTabBarToIndex:currentItemIndex fromIndex:_currentItemIndex];
    _currentItemIndex = currentItemIndex;
}

- (void)updateData
{
    _arrowButton.backgroundColor = self.backgroundColor;
    
    _itemsWidth = [self getButtonsWidthWithTitles:_itemTitles];
    if (_itemsWidth.count)
    {
        CGFloat contentWidth = [self contentWidthAndAddNavTabBarItemsWithButtonsWidth:_itemsWidth];
        _navgationTabBar.contentSize = CGSizeMake(contentWidth, DOT_COORDINATE);
    }
}

- (void)refresh
{
    [self popItemMenu:_popItemMenu];
}

#pragma mark - SCFunctionView Delegate Methods
#pragma mark -
- (void)itemPressedWithIndex:(NSInteger)index
{
    [self functionButtonPressed];
    [_delegate itemDidSelectedWithIndex:index];
}

@end
