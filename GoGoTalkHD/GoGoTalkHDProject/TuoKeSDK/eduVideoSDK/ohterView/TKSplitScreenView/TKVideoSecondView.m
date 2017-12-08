//
//  TKVideoSecondView.m
//  EduClassPad
//
//  Created by lyy on 2017/11/23.
//  Copyright © 2017年 beijing. All rights reserved.
//

#import "TKVideoSecondView.h"
#import "TKVideoSmallView.h"

@implementation TKVideoSecondView

- (void)setVideoSmallViewArray:(NSMutableArray *)videoSmallViewArray{
    
    CGFloat videoBackWidth = CGRectGetWidth(self.frame);
    CGFloat videoBackHeight = CGRectGetHeight(self.frame);
    
    TKVideoSmallView *oneView =(TKVideoSmallView *) videoSmallViewArray[0];
    [self addSubview:oneView];
    oneView.frame = CGRectMake(0, 0, videoBackWidth/2, videoBackHeight);
    
    TKVideoSmallView *secondView =(TKVideoSmallView *) videoSmallViewArray[1];
    [self addSubview:secondView];
    secondView.frame = CGRectMake(videoBackWidth/2, 0, videoBackWidth/2, videoBackHeight);
    
   
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
