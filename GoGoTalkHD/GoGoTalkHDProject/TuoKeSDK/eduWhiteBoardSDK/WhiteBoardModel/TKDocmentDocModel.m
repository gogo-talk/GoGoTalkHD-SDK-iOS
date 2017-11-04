//
//  TKDocmentDocModel.m
//  EduClassPad
//
//  Created by ifeng on 2017/5/31.
//  Copyright © 2017年 beijing. All rights reserved.
//

#import "TKDocmentDocModel.h"
#import "TKMacro.h"
@implementation TKDocmentDocModel
- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    NSLog(@"%@--%@没有定义%@",@(__FILE__),@(__FUNCTION__), key);
    
}
-(void)dynamicpptUpdate{
    //如果是动态ppt
    if ([_dynamicppt intValue]) {
        if (_downloadpath) {
            _swfpath = [_downloadpath copy];
        }
        _action = sActionShow;
    }else{
        _action = @"";
    }
}

- (void)resetToDefault {
    self.currpage = [[NSNumber alloc] initWithInt:1];
    self.pptstep = [[NSNumber alloc] initWithInt:0];
    self.steptotal = [[NSNumber alloc] initWithInt:0];
    self.pptslide = [[NSNumber alloc] initWithInt:1];
    if (self.fileid.intValue == 0) {
        self.pagenum = [[NSNumber alloc] initWithInt:1];
    }
}

@end
