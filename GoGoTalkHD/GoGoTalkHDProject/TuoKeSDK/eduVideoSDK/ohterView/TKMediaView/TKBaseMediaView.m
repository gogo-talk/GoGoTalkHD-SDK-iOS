//
//  TKBaseMediaView.m
//  EduClassPad
//
//  Created by ifeng on 2017/8/29.
//  Copyright © 2017年 beijing. All rights reserved.
//

#import "TKBaseMediaView.h"
#import "TKProgressSlider.h"
#import "TKEduSessionHandle.h"
#import "TKUtil.h"
#import "MediaStream.h"

@implementation TKBaseMediaView

- (instancetype)initWithMediaStream:(MediaStream *)aMediaStream
                              frame:(CGRect)frame

{
    self = [super initWithFrame:frame];
    if (self) {
        
        _iMediaStream = aMediaStream;
        _isPlayEnd      = NO;
        _duration       = aMediaStream.duration;
        
        [TKEduSessionHandle shareInstance].isPlayMedia = YES;
        
        [[NSNotificationCenter defaultCenter]postNotificationName:sTapTableNotification object:nil];
        
        if (aMediaStream.hasVideo) {
            [self ac_initVideoSubviews];
        }else{
            [self ac_initAudioSubviews];
        }
        [[NSNotificationCenter defaultCenter]removeObserver:self];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(unPluggingHeadSet:) name:sUnunpluggingHeadsetNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(pluggInMicrophone:) name:sPluggInMicrophoneNotification object:nil];
        
    }
    return self;
}
-(void)unPluggingHeadSet:(NSNotification *)notifi{
    
    [self audioVolum: [TKEduSessionHandle shareInstance].iVolume];
    
    
}
-(void)pluggInMicrophone:(NSNotification *)notifi{
    [self audioVolum: [TKEduSessionHandle shareInstance].iVolume];
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
// 添加view，子类实现
- (void)ac_initAudioSubviews {
    
    if ([TKEduSessionHandle shareInstance].localUser.role==2) {
        self.iDiskButtion = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 57, 57)];
        [self.iDiskButtion setImage:LOADIMAGE(@"disk") forState:UIControlStateNormal];
        if ( _iMediaStream.isPlay) {
            
            CABasicAnimation *tRotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            tRotationAnimation.toValue     = [NSNumber numberWithFloat: M_PI * 2.0 ];
            tRotationAnimation.duration    = 1;
            tRotationAnimation.cumulative  = YES;
            tRotationAnimation.repeatCount = HUGE_VALF;
            tRotationAnimation.removedOnCompletion = NO;
            [self.iDiskButtion.layer addAnimation:tRotationAnimation forKey:@"rotationAnimation"];
            
        }
        [self addSubview:self.iDiskButtion];
        //播放按钮
        self.playButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 0, 57, 57)];
        [self.playButton setImage:LOADIMAGE(@"playBtn") forState:UIControlStateNormal];
        [self.playButton setImage:LOADIMAGE(@"pauseBtn") forState:UIControlStateSelected];
        [self.playButton addTarget:self action:@selector(playOrPauseAction:) forControlEvents:UIControlEventTouchUpInside];
        self.playButton.selected = _iMediaStream.isPlay;
        self.backgroundColor = [UIColor clearColor];
        
        return;
    }
    self.backgroundColor = RGBCOLOR(23, 23, 23);
    
    //返回按钮
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.frame)-40, (CGRectGetHeight(self.frame)-30)/2, 30, 30)];
    
    [self.backButton setImage:LOADIMAGE(@"btn_closed_normal") forState:UIControlStateNormal];
    //    self.backButton.backgroundColor = [UIColor yellowColor];
    [self.backButton addTarget:self action:@selector(backAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.backButton];
    
    //播放按钮
    self.playButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 0, 57, 57)];
    [self.playButton setImage:LOADIMAGE(@"playBtn") forState:UIControlStateNormal];
    [self.playButton setImage:LOADIMAGE(@"pauseBtn") forState:UIControlStateSelected];
    [self.playButton addTarget:self action:@selector(playOrPauseAction:) forControlEvents:UIControlEventTouchUpInside];
    self.playButton.selected = _iMediaStream.isPlay;
    [self addSubview:self.playButton];
    
    //名称
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.playButton.frame)+20, 0, 315, 25)];
    self.titleLabel.text = self.iMediaStream.filename;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:self.titleLabel];
    
    //时间
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.titleLabel.frame), 0, 110, 25)];
    self.timeLabel.text = @"00:00/00:00";
    self.titleLabel.font = TKFont(12);
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:self.timeLabel];
    CGSize size = CGSizeMake(1000,10000);
    //计算实际frame大小，并将label的frame变成实际大小
    NSDictionary *attribute = @{NSFontAttributeName:self.timeLabel.font};
    CGSize labelsize = [self.timeLabel.text boundingRectWithSize:size options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil].size;
    self.timeLabel.frame = CGRectMake(CGRectGetMaxX(self.titleLabel.frame), 0, labelsize.width+10, labelsize.height);
    // 进度拖拽滑块
    self.iProgressSlider = [[TKProgressSlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.playButton.frame)+20, 25, 425, 25) direction:AC_SliderDirectionHorizonal];
    [self addSubview:self.iProgressSlider];
    
    [self.iProgressSlider addTarget:self action:@selector(progressValueChange:) forControlEvents:UIControlEventValueChanged];
    // 声音开关按钮
    self.iAudioButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.iProgressSlider.frame)+20, 25, 25, 25)];
    [self.iAudioButton setImage:LOADIMAGE(@"btn_volume_normal") forState:UIControlStateNormal];
    [self.iAudioButton setImage:LOADIMAGE(@"btn_mute_normal") forState:UIControlStateSelected];
    [self.iAudioButton addTarget:self action:@selector(audioButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.iAudioButton];
    //声道滑块
    self.iAudioslider = [[TKProgressSlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.iAudioButton.frame)+8, 25, 150, 25) direction:AC_SliderDirectionHorizonal];
    self.iAudioslider.enabled = YES;
    self.iAudioslider.sliderPercent = 1;
    [self.iAudioslider addTarget:self action:@selector(audioVolumChange:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.iAudioslider];
}

- (void)ac_initVideoSubviews
{
    if ([TKEduSessionHandle shareInstance].localUser.role==2) {
        return;
    }
    self.backgroundColor = RGBCOLOR(23, 23, 23);
    //返回按钮
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenW-60, 10, 50, 50)];
    [self.backButton setImage:LOADIMAGE(@"btn_closed_normal") forState:UIControlStateNormal];
    [self.backButton setImage:LOADIMAGE(@"btn_closed_pressed") forState:UIControlStateHighlighted];
    [self.backButton addTarget:self action:@selector(backAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.backButton];
    
    CGFloat tBottmViewWH = 70;
    CGFloat tViewCap = 8;
    //bottonBar
    self.bottmView = [[UIView alloc] initWithFrame:CGRectMake(0, ScreenH-tBottmViewWH, ScreenW, tBottmViewWH)];
    self.bottmView.backgroundColor = RGBACOLOR(0, 0, 0, .5);
    [self addSubview:self.bottmView];
    
    //播放按钮
    self.playButton = [[UIButton alloc] initWithFrame:CGRectMake(tViewCap, 0, tBottmViewWH, tBottmViewWH)];
    [self.playButton setImage:LOADIMAGE(@"playBtn") forState:UIControlStateNormal];
    [self.playButton setImage:LOADIMAGE(@"pauseBtn") forState:UIControlStateSelected];
    [self.playButton addTarget:self action:@selector(playOrPauseAction:) forControlEvents:UIControlEventTouchUpInside];
    self.playButton.selected = _iMediaStream.isPlay;
    [self.bottmView addSubview:self.playButton];
    
    //声道滑块
    CGFloat tAudiosliderWidth = 107;
    self.iAudioslider = [[TKProgressSlider alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bottmView.frame)-tAudiosliderWidth-tViewCap, 0, tAudiosliderWidth, CGRectGetHeight(self.bottmView.frame)) direction:AC_SliderDirectionHorizonal];
    self.iAudioslider.enabled = YES;
    self.iAudioslider.sliderPercent = 1;
    [self.iAudioslider addTarget:self action:@selector(audioVolumChange:) forControlEvents:UIControlEventValueChanged];
    [self.bottmView addSubview:self.iAudioslider];
    //声音按钮
    self.iAudioButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMinX(self.iAudioslider.frame)-25,(CGRectGetHeight(self.bottmView.frame)-25)/2, 25, 25)];
    [self.iAudioButton setImage:LOADIMAGE(@"btn_volume_normal") forState:UIControlStateNormal];
    [self.iAudioButton setImage:LOADIMAGE(@"btn_mute_normal") forState:UIControlStateSelected];
    [self.iAudioButton addTarget:self action:@selector(audioButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottmView addSubview:self.iAudioButton];
    //名称
    CGFloat tProgressSliderW = CGRectGetWidth(self.bottmView.frame) - CGRectGetMaxX(self.playButton.frame)-(CGRectGetWidth(self.bottmView.frame)-CGRectGetMinX(self.iAudioButton.frame))-tViewCap-70*Proportion;
    //进度滑块
    self.iProgressSlider = [[TKProgressSlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.playButton.frame)+tViewCap, 33, tProgressSliderW, 25) direction:AC_SliderDirectionHorizonal];
    
    [self.iProgressSlider addTarget:self action:@selector(progressValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.bottmView addSubview:self.iProgressSlider];
    //时间
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 25)];
    self.timeLabel.text = @"00:00/00:00";
    self.titleLabel.font = TKFont(12);
    self.timeLabel.textColor = RGBACOLOR_Title_White;
    self.timeLabel.textAlignment = NSTextAlignmentLeft;
    [self.bottmView addSubview:self.timeLabel];
    
    CGSize size = CGSizeMake(1000,10000);
    //计算实际frame大小，并将label的frame变成实际大小
    NSDictionary *attribute = @{NSFontAttributeName:self.timeLabel.font};
    CGSize labelsize = [self.timeLabel.text boundingRectWithSize:size options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil].size;
    self.timeLabel.frame = CGRectMake(CGRectGetMaxX(self.iProgressSlider.frame)- labelsize.width-10, 8, labelsize.width+10, labelsize.height);
    
    self.titleLabel      = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.playButton.frame)+tViewCap, 8, tProgressSliderW- labelsize.width-10, 25)];
    self.titleLabel.text = self.iMediaStream.filename;
    self.titleLabel.textColor = RGBACOLOR_Title_White;
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self.bottmView addSubview:self.titleLabel];
    //菊花
    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.activity setCenter:self.center];//指定进度轮中心点
    [self.activity setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];//设置进度轮显示类型
    self.activity.hidesWhenStopped = YES;
    [self addSubview:self.activity];
    
}
#pragma mark - 响应事件

// 点击退出
- (void)backAction:(UIButton *)button {
    
    [TKEduSessionHandle shareInstance].isPlayMedia          = NO;
    [[TKEduSessionHandle shareInstance]sessionHandleUnpublishMedia:nil];

    
}
//-1
// 播放和暂停
- (void)playOrPauseAction:(UIButton *)sender {
    
    [self playAction:!sender.selected];
}

- (void)playAction:(BOOL)start {
    NSLog(@"jin-------%@",@(self.playButton.selected));
    if (self.playButton.selected == start) {
        return;
    }
   
    [[TKEduSessionHandle shareInstance]sessionHandleMediaPause:!start];
     [[TKEduSessionHandle shareInstance]configurePlayerRoute: NO isCancle:NO];
    //[[TKEduSessionHandle shareInstance]configurePlayerRoute:start isCancle:NO];
    
}
-(void)updatePlayUI:(BOOL)start{
    if (self.playButton.selected == start) {
        return;
    }
    //学生的时候
    if ([TKEduSessionHandle shareInstance].localUser.role == 2) {
        if (start ) {
            [self.iDiskButtion.layer removeAllAnimations];
            CABasicAnimation *tRotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            tRotationAnimation.toValue     = [NSNumber numberWithFloat: M_PI * 2.0 ];
            tRotationAnimation.duration    = 1;
            tRotationAnimation.cumulative  = YES;
            tRotationAnimation.repeatCount = HUGE_VALF;
            tRotationAnimation.removedOnCompletion = NO;
            [self.iDiskButtion.layer addAnimation:tRotationAnimation forKey:@"rotationAnimation"];
        }else{
            [self.iDiskButtion.layer removeAllAnimations];
        }
        
    }
    self.playButton.selected = start;
    self.iIsPlay = start;
}

// 播放进度滑块
- (void)progressValueChange:(TKProgressSlider *)slider {
    
    NSTimeInterval pos = self.iProgressSlider.sliderPercent * self.duration;
    [self seekProgressToPos:pos];
    
}
-(void)seekProgressToPos:(NSTimeInterval)value{
    [[TKEduSessionHandle shareInstance]sessionHandleMediaSeektoPos:value];
}

// 声音开关
-(void)audioButtonClicked:(UIButton *)aButton{
    
    BOOL tBtnSlct                   = self.iAudioslider.sliderPercent ?NO:YES;
    aButton.selected                = !tBtnSlct;
    CGFloat tVolume                 = aButton.selected ? 0 : 1;
    [TKEduSessionHandle shareInstance].iVolume  = tVolume;
    self.iAudioslider.sliderPercent = tVolume;
    [[TKEduSessionHandle shareInstance]sessionHandleMediaVolum:tVolume];
}

// 音量大小滑块
- (void)audioVolumChange:(TKProgressSlider *)slider {
  
    [self audioVolum:slider.value];
   
}

-(void)audioVolum:(CGFloat)volum{
    _iAudioButton.selected = (volum==0);
    [TKEduSessionHandle shareInstance].iVolume = volum;
    [[TKEduSessionHandle shareInstance]sessionHandleMediaVolum:volum*10];
}
- (void)update:(NSTimeInterval)current total:(NSTimeInterval)total
{
  
    //如果用户在手动滑动滑块，则不对滑块的进度进行设置重绘
    if (!self.iProgressSlider.isSliding) {
        self.iProgressSlider.sliderPercent = current/total;
    }
    
    if (current!=self.lastTime) {
        [self.activity stopAnimating];
        self.timeLabel.text = [NSString stringWithFormat:@"%@/%@", [self formatPlayTime:current/1000], isnan(total)?@"00:00":[self formatPlayTime:total/1000]];
    } else {
        if (current < total) {
            [self.activity startAnimating];
        }
    }
    
    self.lastTime = current;
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if(now - self.lastSyncTime > 1) {
        self.lastSyncTime = now;
    }
}

- (NSString *)formatPlayTime:(NSTimeInterval)duration {
    int minute = 0, hour = 0, secend = duration;
    minute = (secend % 3600)/60;
    hour = secend / 3600;
    secend = secend % 60;
    return [NSString stringWithFormat:@"%02d:%02d", minute, secend];
}

@end