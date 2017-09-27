//
//  RoomController.m
//  classdemo
//
//  Created by mac on 2017/4/28.
//  Copyright © 2017年 talkcloud. All rights reserved.
//

#import "RoomController.h"
#import "RoomManager.h"
#import "TKEduBoardHandle.h"
#import "TKEduRoomProperty.h"
#import "TKEduSessionHandle.h"
#import <WebKit/WebKit.h>
#import "TKVideoSmallView.h"
#import "TKUtil.h"
#import "TKMacro.h"
//reconnection
#import "TKNONetWorkView.h"
#import "TKTimer.h"
#import "TKAFNetworkReachabilityManager.h"
#import "TKProgressHUD.h"
#import "TKRCGlobalConfig.h"
//chatView
#import "TKLiveViewChatTableViewCell.h"
#import "TKGrowingTextView.h"
#import "TKChatMessageModel.h"
//getGifNum
#import "TKEduNetManager.h"
#import "TKClassTimeView.h"


#pragma pad
#import "TKMessageTableViewCell.h"
#import "TKTeacherMessageTableViewCell.h"
#import "TKStudentMessageTableViewCell.h"
#import "TKDocumentListView.h"
#import "TKChatView.h"
#import "BITAttributedLabel.h"
//#import "UIButton+clickedOnce.h"
#import "UIControl+clickedOnce.h"

#import "TKBaseMediaView.h"
#import "TKMediaDocModel.h"
#import "TKDocmentDocModel.h"

#import "GGT_PopoverController.h"

@import AVFoundation;

//214 *142

#define VideoSmallViewMargins 6
#define VideoSmallViewHeigh (([UIScreen mainScreen].bounds.size.height -3*VideoSmallViewMargins-40)/ 4.0)
#define VideoSmallViewWidth VideoSmallViewHeigh * 4.0/3.0



#define VideoSmallViewBigWidth  (([UIScreen mainScreen].bounds.size.width -3*VideoSmallViewMargins)/ 2.0)
#define VideoSmallViewBigHeigh (VideoSmallViewBigWidth * 3.0/4.0)

#define VideoSmallViewLittleWidth  (([UIScreen mainScreen].bounds.size.width -6*VideoSmallViewMargins)/ 5.0)
#define VideoSmallViewLittleHeigh (VideoSmallViewLittleWidth * 3.0/4.0)


@interface TGInputToolBarView : UIView
@end
@implementation TGInputToolBarView
- (void)drawRect:(CGRect) rect
{
    [super drawRect:rect];
    
    [RGBCOLOR(76,76,76) set];
    //[[UIColor redColor] set];
    
    CGRect frame = self.bounds;
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(currentContext,1.0f);
    CGContextMoveToPoint(currentContext, frame.origin.x, frame.origin.y);
    CGContextAddLineToPoint(currentContext, frame.origin.x + frame.size.width, frame.origin.y);
    CGContextStrokePath(currentContext);
}

@end

//RGBCOLOR(121, 69, 67); 举手红色暗色 下课
//RGBCOLOR(207,65, 21); 红色
static const CGFloat sChatBarHeight = 47;

int expireSeconds;      // 课堂结束时间

#pragma mark nav
static const CGFloat sDocumentButtonWidth = 55;
static const CGFloat sRightWidth          = 234;
static const CGFloat sClassTimeViewHeigh  = 57.5;
static const CGFloat sViewCap             = 10;
static const CGFloat sBottomViewHeigh     = 132;
static const CGFloat sTeacherVideoViewHeigh     = 182;

static const CGFloat sStudentVideoViewHeigh     = 112;
static const CGFloat sStudentVideoViewWidth     = 120;
static const CGFloat sRightViewChatBarHeight    = 50;
static const CGFloat sSendButtonWidth           = 64;
static NSString *const sMessageCellIdentifier           = @"messageCellIdentifier";
static NSString *const sStudentCellIdentifier           = @"studentCellIdentifier";
static NSString *const sDefaultCellIdentifier           = @"defaultCellIdentifier";

//https://imtx.me/archives/1933.html 黑色背景
@interface RoomController() <TKEduBoardDelegate,TKEduSessionDelegate,UIGestureRecognizerDelegate,UIScrollViewDelegate,UITableViewDelegate,UITableViewDataSource,TKGrowingTextViewDelegate,CAAnimationDelegate,UIPopoverPresentationControllerDelegate>


//其他
@property(nonatomic,retain)UIScrollView *iScroll;
//@property (nonatomic, assign) BOOL isMuteAudio;//yes 静音 no 非静音
@property (nonatomic, assign) BOOL iIsCanRaiseHandUp;//是否可以举手
@property (nonatomic, assign) NSDictionary* iParamDic;//加入会议paraDic
@property (nonatomic, assign) UserType iUserType;//当前身份
@property (nonatomic, assign) RoomType iRoomType;//当前会议室
@property(nonatomic,strong)TKChatView *iChatView;//聊天

//导航
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UILabel *titleLable;
@property (nonatomic, strong) UIButton *leftButton;

@property (nonatomic, strong) UIButton *iDocumentButton;
@property (nonatomic, strong) UIButton *iMediaButton;
@property (nonatomic, strong) UIButton *iUserButton;

@property (nonatomic, strong) TKClassTimeView *iClassTimeView;

@property (nonatomic, assign) NSTimeInterval iLocalTime;
@property (nonatomic, assign) NSTimeInterval iClassStartTime;
@property (nonatomic, assign) NSTimeInterval iServiceTime;
@property(nonatomic,copy)     NSString * iRoomName;
@property (nonatomic, strong) NSTimer *iNavHideControltimer;
@property (nonatomic, strong) NSTimer *iClassTimetimer;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, assign) NSTimeInterval iClassReadyTime;
@property (nonatomic, strong) NSTimer *iClassReadyTimetimer;
#pragma mark pad
@property(nonatomic,retain)UIView   *iRightView;
@property(nonatomic,retain)UIView   *iBottomView;
@property(nonatomic,retain)UIButton *iClassBeginAndRaiseHandButton;
@property(nonatomic,retain)UIView   *iMuteAudioAndRewardView;
@property(nonatomic,retain)UIButton *iMuteAudioButton;
@property(nonatomic,retain)UIButton *iRewardButton;
@property(nonatomic,retain)TKDocumentListView *iDocumentListView;
@property(nonatomic,retain)TKDocumentListView *iUsertListView;
@property(nonatomic,retain)TKDocumentListView *iMediaListView;
//白板
@property (nonatomic, assign) BOOL iCandraw;//yes 能画 no 不能

@property (nonatomic, assign) BOOL iShowBefore;//yes 出现过 no 没出现过
@property (nonatomic, assign) BOOL iShow;//yes 出现过 no 没出现过

//视频
@property (nonatomic, strong) TKEduRoomProperty *iRoomProperty;
@property (nonatomic, strong) TKEduSessionHandle *iSessionHandle;
@property (nonatomic, weak)  id<TKEduRoomDelegate> iRoomDelegate;
@property (nonatomic, strong) TKVideoSmallView *iTeacherVideoView;
@property (nonatomic, strong) TKVideoSmallView *iOurVideoView;
@property (nonatomic, strong) NSMutableArray  *iStudentVideoViewArray;

@property (nonatomic, strong) TKBaseMediaView  *iMediaView;

@property (nonatomic, strong) TKTimer   *iCheckPlayVideotimer;
@property (nonatomic, strong) NSArray   *iUserPlayVideoArrayPre;
@property (nonatomic, strong) NSArray   *iUserPlayVideoArrayDic;


//断线重连
@property (nonatomic, strong) TKNONetWorkView *iNoNetView;
@property (nonatomic, strong) TKAFNetworkReachabilityManager *iAFNetworkReachablitityManager;
@property (nonatomic, assign) BOOL iNetStatus;//yes 有网 no 无网
@property (nonatomic, assign) BOOL iNetConnectionStatus;//yes 重连状态 no 非重连状态
@property (nonatomic, assign) BOOL iIsTellClassBegin;//yes 有网 no 无网
@property (nonatomic, strong) TKTimer *iReconnectTimeOutTimer;//重连超时
@property (nonatomic, strong) NSTimer *connectTimer;
@property (nonatomic, strong) TKProgressHUD *connectHUD;
@property (nonatomic, assign) NSInteger iReconnectCount;
@property (nonatomic, strong) TKProgressHUD *HUD;
@property (nonatomic, assign) BOOL errorOccured;
//聊天
@property (nonatomic, strong) UITableView *iChatTableView; // 聊天tableView
@property (nonatomic, strong) TGInputToolBarView *inputContainer;
@property (nonatomic, strong) TGInputToolBarView *inputInerContainer;
@property (nonatomic, strong) TKGrowingTextView *inputField;
@property (nonatomic, strong) UIButton *sendButton;

@property(nonatomic,retain)UIView *iChatInputView;//全屏
@property (nonatomic, strong) UILabel *replyText;
@property (nonatomic,assign) CGRect inputContainerFrame;
@property (nonatomic,assign) CGFloat knownKeyboardHeight;
@property (nonatomic,strong ) NSArray  *iMessageList;


@property (nonatomic, strong) NSMutableArray *xc_phraseMuArray;
@property (nonatomic, strong) UIButton *xc_commonButton;

@end

@implementation RoomController


-(void)testChat{
    //导航栏
    _iChatInputView = ({
        
        UIView *tChatInputView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, ScreenW, ScreenH)];
        tChatInputView.backgroundColor =  RGBCOLOR(41, 41, 41) ;
        
        tChatInputView;
    });
    
    
    
    
    
    [[UIApplication sharedApplication].keyWindow addSubview:_iChatInputView];
}
- (instancetype)initWithDelegate:(id<TKEduRoomDelegate>)aRoomDelegate
                       aParamDic:(NSDictionary *)aParamDic
                       aRoomName:(NSString *)aRoomName
                   aRoomProperty:(TKEduRoomProperty *)aRoomProperty{
    if (self = [self init]) {
        _iRoomDelegate      = aRoomDelegate;
        _iRoomProperty      = aRoomProperty;
        _iRoomName          = aRoomName;
        _iParamDic          = aParamDic;
        // _iBoardHandle  = [TKEduBoardHandle shareTKEduWhiteBoardHandleInstance];
        _iSessionHandle = [TKEduSessionHandle shareInstance];
        
        // 下课定时器
        _iClassTimetimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                            target:self
                                                          selector:@selector(onClassTimer)
                                                          userInfo:nil
                                                           repeats:YES];
        [_iClassTimetimer setFireDate:[NSDate distantFuture]];
        
        // 上课定时器
        _iClassReadyTimetimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                 target:self
                                                               selector:@selector(onClassReady)
                                                               userInfo:nil
                                                                repeats:YES];
        [_iClassReadyTimetimer setFireDate:[NSDate distantFuture]];
        
        [_iSessionHandle configureSession:aParamDic aRoomDelegate:aRoomDelegate aSessionDelegate:self aBoardDelegate:self aRoomProperties:aRoomProperty];
    }
    return self;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear: animated];
    [self addNotification];
    if (!_iCheckPlayVideotimer) {
        [self createTimer];
    }
    
}
-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    [self invalidateTimer];
    [self removeNotificaton];
    
    
}
-(void)addNotification{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(fullScreenToLc:) name:sfullScreenToLc object:nil];
    /** 1.先设置为外放 */
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    //    });
    /** 2.判断当前的输出源 */
    // [self routeChange:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(routeChange:)
                                                name:AVAudioSessionRouteChangeNotification
                                              object:[AVAudioSession sharedInstance]];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(tapTable:)
                                                name:sTapTableNotification
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refreshData)
                                                name:@"test"
                                              object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAudioSessionInterruption:)
                                                 name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaServicesReset:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification object:nil];
    
    
}
-(void)removeNotificaton{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
    
    
}
-(void)fullScreenToLc:(NSNotification*)aNotification{
    bool isFull = [aNotification.object boolValue];
    _iClassTimeView.hidden = isFull;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    CGRect tFrame = [UIScreen mainScreen].bounds;
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars             = NO;
    self.modalPresentationCapturesStatusBarAppearance = NO;
    self.automaticallyAdjustsScrollViewInsets         =NO;
    _iNetConnectionStatus = NO;
    if (_iUserType==UserType_Teacher) {
        _iCandraw             = YES;
    }else{
        _iCandraw             = NO;
    }
    
    _iIsCanRaiseHandUp    = YES;
    _iShow     = false;
    _iUserType = _iRoomProperty.iUserType;
    _iRoomType = _iRoomProperty.iRoomType;
    
    _iScroll = ({
        
        UIScrollView *tScrollView = [[UIScrollView alloc]initWithFrame:tFrame];
        tScrollView.userInteractionEnabled = YES;
        tScrollView.delegate = self;
        tScrollView.contentSize = CGSizeMake(CGRectGetWidth(tFrame), CGRectGetHeight(tFrame));
        tScrollView.backgroundColor =  RGBCOLOR(62,62,62);
        tScrollView;
        
        
    });
    
    [self.view addSubview:_iScroll];
    [self initNavigation:tFrame];
    [self initRightView];
    [self initBottomView];
    [self initWhiteBoardView];
    [self initTapGesTureRecognizer];
    //[self initAutoReconection];
    [self createTimer];
    [_iScroll bringSubviewToFront:_iTKEduWhiteBoardView];
    [_iScroll bringSubviewToFront:_iClassTimeView];
    //todo
    [self configureHUD:@"" aIsShow:YES];
    [self initAudioSession];
    // 没有发生断线重连
    self.errorOccured = NO;
    
    [self xc_loadPhraseData];
}


/// 获取聊天界面 常用语数据
- (void)xc_loadPhraseData
{
    self.xc_phraseMuArray = [NSMutableArray array];
    
    [[BaseService share] sendGetRequestWithPath:URL_GetContrastInfo token:YES viewController:self showMBProgress:NO success:^(id responseObject) {
        
        NSArray *data = responseObject[@"data"];
        [data enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            GGT_CoursePhraseModel *model = [GGT_CoursePhraseModel yy_modelWithDictionary:obj];
            [self.xc_phraseMuArray addObject:model];
        }];
        
    } failure:^(NSError *error) {
        
    }];
}


-(void)configureHUD:(NSString *)aString  aIsShow:(BOOL)aIsShow{
    if (aIsShow) {
        if (!_HUD) {
            _HUD = [[TKProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
            [[UIApplication sharedApplication].keyWindow addSubview:_HUD];
            _HUD.dimBackground = YES;
            _HUD.removeFromSuperViewOnHide = YES;
        }
        if ([aString length] > 0) {
            _HUD.labelText          = aString;
        }
        
        [_HUD show:YES];
    }else{
        [_HUD hide:YES];
        _HUD = nil;
    }
}
-(void)initAutoReconection{
    _iAFNetworkReachablitityManager = [TKAFNetworkReachabilityManager sharedManager];
    
    __weak typeof(self)weekSelf = self;
    // 2.设置网络状态改变后的处理
    [_iAFNetworkReachablitityManager setReachabilityStatusChangeBlock:^(TKAFNetworkReachabilityStatus status) {
        __strong typeof(self)strongSelf = weekSelf;
        
        // 当网络状态改变了, 就会调用这个block
        switch (status) {
            case TKAFNetworkReachabilityStatusUnknown: // 未知网络
            case TKAFNetworkReachabilityStatusNotReachable: // 没有网络(断网)
            {
                TKLog(@"没有网络(断网)");
                [strongSelf leftRoomAbnormal];
                
                
                break;
            }
                
            case TKAFNetworkReachabilityStatusReachableViaWWAN: // 手机自带网络
            case TKAFNetworkReachabilityStatusReachableViaWiFi: // WIFI
            {
                TKLog(@"手机自带网络或者Wifi");
                [strongSelf joinRoomReconnected];
                
                
                break;
            }
                
        }
    }];
    [_iAFNetworkReachablitityManager startMonitoring];
}

#pragma mark Pad 初始化

-(void)initAudioSession{
    
    AVAudioSession* session = [AVAudioSession sharedInstance];
    NSError* error;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth  error:&error];
    [session setMode:AVAudioSessionModeVoiceChat error:nil];
    [session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
    AVAudioSessionRouteDescription*route = [[AVAudioSession sharedInstance]currentRoute];
    for (AVAudioSessionPortDescription * desc in [route outputs]) {
        
        if ([[desc portType]isEqualToString:AVAudioSessionPortBuiltInReceiver]) {
            [TKEduSessionHandle shareInstance].isHeadphones = NO;
            [TKEduSessionHandle shareInstance].iVolume = 1;
            [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        }else{
            [TKEduSessionHandle shareInstance].isHeadphones = YES;
            [TKEduSessionHandle shareInstance].iVolume = 0.5;
        }
        /*
         if ([[desc portType] isEqualToString:@"Headphones"] || [[desc portType] isEqualToString:@"BluetoothHFP"])
         {
         [TKEduSessionHandle shareInstance].isHeadphones = YES;
         [TKEduSessionHandle shareInstance].iVolume = 0.5;
         }
         else
         {
         [TKEduSessionHandle shareInstance].isHeadphones = NO;
         [TKEduSessionHandle shareInstance].iVolume = 1;
         [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
         }*/
        
    }
    
}
-(void)initNavigation:(CGRect)aFrame{
    self.navigationController.navigationBar.hidden = YES;
    //导航栏
    _titleView = ({
        
        UIView *tTitleView = [[UIView alloc] initWithFrame: CGRectMake(0, 20, CGRectGetWidth(aFrame), sDocumentButtonWidth*Proportion)];
        tTitleView.backgroundColor =  RGBCOLOR(41, 41, 41) ;
        tTitleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        tTitleView;
    });
    
    
    
    _leftButton =({
        
        UIButton *tLeftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        tLeftButton.frame = CGRectMake(0, 0, sDocumentButtonWidth*Proportion, sDocumentButtonWidth*Proportion);
        //        tLeftButton.center = CGPointMake(25+8, _titleView.center.y);
        tLeftButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        
        [tLeftButton setImage: LOADIMAGE(@"btn_back_normal") forState:UIControlStateNormal];
        [tLeftButton setImage: LOADIMAGE(@"btn_back_pressed") forState:UIControlStateHighlighted];
        [tLeftButton addTarget:self action:@selector(leftButtonPress) forControlEvents:UIControlEventTouchUpInside];
        tLeftButton;
        
        
    });
    
    [_titleView addSubview:_leftButton];
    
    
    _titleLable = ({
        
        UILabel *tTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(65, 0, self.view.frame.size.width-65-sDocumentButtonWidth*4- 8* 4, sDocumentButtonWidth*Proportion)];
        NSAttributedString * attrStr =  [[NSAttributedString alloc]initWithData:[_iSessionHandle.roomName dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)} documentAttributes:nil error:nil];
        tTitleLabel.text = attrStr.string ;
        tTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tTitleLabel.backgroundColor = [UIColor clearColor];
        tTitleLabel.textAlignment = NSTextAlignmentLeft;
        tTitleLabel.font = TKFont(21);
        tTitleLabel.textColor = RGBCOLOR(255, 255, 255);
        tTitleLabel;
        
    });
    [_titleView addSubview:_titleLable];
    
    _iUserButton = ({
        
        UIButton *tUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
        tUserButton.frame = CGRectMake(ScreenW-sDocumentButtonWidth*Proportion-8, 0, sDocumentButtonWidth*Proportion, sDocumentButtonWidth*Proportion);
        
        tUserButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [tUserButton addTarget:self action:@selector(userButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [tUserButton setImage: LOADIMAGE(@"btn_user_normal") forState:UIControlStateNormal];
        [tUserButton setImage: LOADIMAGE(@"btn_user_pressed") forState:UIControlStateSelected];
        tUserButton;
        
    });
    
    
    _iMediaButton = ({
        
        UIButton *tMediaButton = [UIButton buttonWithType:UIButtonTypeCustom];
        tMediaButton.frame = CGRectMake(ScreenW-sDocumentButtonWidth*Proportion*((2))-8*(2), 0, sDocumentButtonWidth*Proportion, sDocumentButtonWidth*Proportion);
        
        tMediaButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [tMediaButton addTarget:self action:@selector(mediaButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [tMediaButton setImage: LOADIMAGE(@"btn_media_normal") forState:UIControlStateNormal];
        [tMediaButton setImage: LOADIMAGE(@"btn_media_pressed") forState:UIControlStateSelected];
        tMediaButton;
        
    });
    
    _iDocumentButton = ({
        
        UIButton *tDocumentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        tDocumentButton.frame = CGRectMake(ScreenW-sDocumentButtonWidth*Proportion*(3)-8*((3)), 0, sDocumentButtonWidth*Proportion, sDocumentButtonWidth*Proportion);
        
        tDocumentButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [tDocumentButton addTarget:self action:@selector(documentButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [tDocumentButton setImage: LOADIMAGE(@"btn_document_normal") forState:UIControlStateNormal];
        [tDocumentButton setImage: LOADIMAGE(@"btn_document_pressed") forState:UIControlStateSelected];
        tDocumentButton;
        
    });
    if (_iUserType == UserType_Teacher) {
        [_titleView addSubview:_iDocumentButton];
        [_titleView addSubview:_iMediaButton];
        [_titleView addSubview:_iUserButton];
        
    }
    
    [_iScroll addSubview:_titleView];
    
    _iClassTimeView = ({
        
        TKClassTimeView *tClassTimeView = [[TKClassTimeView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(_titleView.frame), ScreenW-sRightWidth*Proportion-50,sClassTimeViewHeigh*Proportion)];
        tClassTimeView.backgroundColor = [UIColor clearColor];
        [tClassTimeView setClassTime:0];
        tClassTimeView;
        
    });
    
    [_iScroll addSubview:_iClassTimeView];
    
}

-(void)classBeginAndRaiseHandButtonClicked:(UIButton *)aButton{
    
    if (_iUserType == UserType_Teacher) {
        aButton.selected = [TKEduSessionHandle shareInstance].isClassBegin;
        if (!aButton.selected) {
            TKLog(@"开始上课");
            UIButton *tButton = _iClassBeginAndRaiseHandButton;
            [self configureHUD:@"" aIsShow:YES];
            __weak typeof(self)weakSelf =self;
            [TKEduNetManager classBeginStar:[TKEduSessionHandle shareInstance].iRoomProperties.iRoomId companyid:[TKEduSessionHandle shareInstance].iRoomProperties.iCompanyID aHost:[TKEduSessionHandle shareInstance].iRoomProperties.sWebIp aPort:[TKEduSessionHandle shareInstance].iRoomProperties.sWebPort aComplete:^int(id  _Nullable response) {
                
                __strong typeof(weakSelf) strongSelf = weakSelf;
                tButton.backgroundColor = RGBACOLOR_ClassEnd_Red;
                [tButton setTitle:MTLocalized(@"Button.ClassIsOver") forState:UIControlStateNormal];
                
                
                if ([TKEduSessionHandle shareInstance].iCurrentDocmentModel) {
                    [[TKEduSessionHandle shareInstance] publishtDocMentDocModel:[TKEduSessionHandle shareInstance].iCurrentDocmentModel To:sTellAllExpectSender];
                }
                [_iSessionHandle sessionHandlePubMsg:sClassBegin ID:sClassBegin To:sTellAll Data:@{} Save:true completion:nil];
                [strongSelf configureHUD:@"" aIsShow:NO];
                return 0;
            } aNetError:^int(id  _Nullable response) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf configureHUD:@"" aIsShow:NO];
                return 0;
            }];
            
        } else {
            
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:MTLocalized(@"Prompt.prompt") message:MTLocalized(@"Prompt.FinishClass") preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *tActionSure = [UIAlertAction actionWithTitle:MTLocalized(@"Prompt.OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                TKLog(@"下课");
                UIButton *tButton = _iClassBeginAndRaiseHandButton;
                [self configureHUD:@"" aIsShow:YES];
                __weak typeof(self)weakSelf =self;
                [_iClassTimetimer invalidate];      // 下课后计时器销毁
                [TKEduNetManager classBeginEnd:[TKEduSessionHandle shareInstance].iRoomProperties.iRoomId companyid:[TKEduSessionHandle shareInstance].iRoomProperties.iCompanyID aHost:[TKEduSessionHandle shareInstance].iRoomProperties.sWebIp aPort:[TKEduSessionHandle shareInstance].iRoomProperties.sWebPort aComplete:^int(id  _Nullable response) {
                    [[TKEduSessionHandle shareInstance] sessionHandleDelMsg:sClassBegin ID:sClassBegin To:sTellAll Data:@{} completion:nil];
                    [tButton setTitle:MTLocalized(@"Button.ClassBegin") forState:UIControlStateNormal];
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf configureHUD:@"" aIsShow:NO];
                    return 0;
                }aNetError:^int(id  _Nullable response) {
                    
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf configureHUD:@"" aIsShow:NO];
                    return 0;
                }];
                
            }];
            
            UIAlertAction *tActionCancel = [UIAlertAction actionWithTitle:MTLocalized(@"Prompt.Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                //
            }];
            
            [ac addAction:tActionSure];
            [ac addAction:tActionCancel];
            
            [self presentViewController:ac animated:YES completion:nil];
        }
        
        
    }else{
        TKLog(@"举手");
        aButton.selected = ![[[TKEduSessionHandle shareInstance].localUser.properties objectForKey:sRaisehand] boolValue];
        [_iSessionHandle sessionHandleChangeUserProperty:_iSessionHandle.localUser.peerID TellWhom:sTellAll Key:sRaisehand Value:@(aButton.selected) completion:nil];
        if (aButton.selected) {
            
            [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.RaiseHandCancle") forState:UIControlStateNormal];
            
        }else{
            
            [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.RaiseHand") forState:UIControlStateNormal];
            
        }
    }
    
    
}
-(void)muteAduoButtonClicked:(UIButton *)aButton{
    TKLog(@"全体静音");
    if (_iUserType == UserType_Student) {
        // 如果当前用户是学生
        [[TKEduSessionHandle shareInstance] disableMyAudio:!aButton.selected];
        
        // 如果禁用音视频，已经举手，举起的手要放下
        BOOL handState = [[[TKEduSessionHandle shareInstance].localUser.properties objectForKey:sRaisehand] boolValue];
        if (handState == YES) {
            [[TKEduSessionHandle shareInstance] sessionHandleChangeUserProperty:[TKEduSessionHandle shareInstance].localUser.peerID TellWhom:sTellAll Key:sRaisehand Value:@(!handState) completion:nil];
            if (!handState) {
                [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.RaiseHandCancle") forState:UIControlStateNormal];
            } else {
                [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.RaiseHand") forState:UIControlStateNormal];
            }
        }
        
        aButton.selected = !aButton.selected;
        [self refreshUI];
        
    } else {
        // 如果当前用户是老师
        if (![TKEduSessionHandle shareInstance].isMuteAudio) {
            
            for (RoomUser *tUser in [_iSessionHandle userStdntAndTchrArray]) {
                
                if ((tUser.role != UserType_Student))
                    continue;
                
                // [_iSessionHandle sessionHandleChangeUserProperty:tUser.peerID TellWhom:tUser.peerID Key:sGiftNumber Value:@(currentGift+1) completion:nil];
                PublishState tState = tUser.publishState;
                if (tState == PublishState_BOTH) {
                    tState = PublishState_VIDEOONLY;
                }else if(tState == PublishState_AUDIOONLY){
                    tState = PublishState_NONE;
                }
                
                [_iSessionHandle sessionHandleChangeUserPublish:tUser.peerID Publish:tState completion:nil];
            }
            [TKEduSessionHandle shareInstance].isMuteAudio = YES;
            _iMuteAudioButton.enabled = NO;
            _iMuteAudioButton.backgroundColor = RGBACOLOR_ClassEnd_Red;
            
        }
        
    }
}
-(void)rewardButtonClicked:(UIButton *)aButton{
    TKLog(@"全员奖励");
    if (_iUserType == UserType_Student) {
        
        // 如果当前用户是学生
        [[TKEduSessionHandle shareInstance] disableMyVideo:!aButton.selected];
        aButton.selected = !aButton.selected;
        
    } else {
        
        // 如果当前用户是老师
        [TKEduNetManager sendGifForRoomUser:[[TKEduSessionHandle shareInstance] userStdntAndTchrArray] roomID:_iRoomProperty.iRoomId  aMySelf:[TKEduSessionHandle shareInstance].localUser aHost:_iRoomProperty.sWebIp aPort:_iRoomProperty.sWebPort aSendComplete:^(id  _Nullable response) {
            
            for (RoomUser *tUser in [[TKEduSessionHandle shareInstance] userStdntAndTchrArray]) {
                int currentGift = 0;
                if ((tUser.role != UserType_Student))
                    continue;
                
                if(tUser && tUser.properties && [tUser.properties objectForKey:sGiftNumber])
                    currentGift = [[tUser.properties objectForKey:sGiftNumber] intValue];
                [[TKEduSessionHandle shareInstance] sessionHandleChangeUserProperty:tUser.peerID TellWhom:sTellAll Key:sGiftNumber Value:@(currentGift+1) completion:nil];
            }
            
        }aNetError:nil];
    }
}
-(void)refreshUI{
    [_iSessionHandle.iBoardHandle refreshUIForFull:NO];
    
    //right
    CGFloat tViewCap = sViewCap*Proportion;
    //老师
    CGFloat tViewWidth = (sRightWidth-2*sViewCap)*Proportion;
    {
        _iTeacherVideoView.frame = CGRectMake(tViewCap, tViewCap, tViewWidth, sTeacherVideoViewHeigh*Proportion);
    }
    //多人时 bottom和whiteview
    {
        
        if (_iRoomType == RoomType_OneToOne) {
            _iBottomView.hidden = YES;
            _iBottomView.frame = CGRectMake(0, ScreenH, ScreenW-sRightWidth*Proportion, 0);
            CGRect tFrame = CGRectMake(0, CGRectGetMaxY(_titleView.frame), ScreenW-sRightWidth*Proportion, (CGRectGetHeight(_iRightView.frame))*Proportion);
            _iTKEduWhiteBoardView.frame = tFrame;
            
            
        } else {
            
            CGRect tFrame = CGRectMake(0, CGRectGetMaxY(_titleView.frame),ScreenW-sRightWidth*Proportion, (CGRectGetHeight(_iRightView.frame)-sBottomViewHeigh)*Proportion);
            _iTKEduWhiteBoardView.frame = tFrame;
            _iBottomView.hidden = NO;
            _iBottomView.frame = CGRectMake(0, ScreenH - sBottomViewHeigh*Proportion, ScreenW-sRightWidth*Proportion, sBottomViewHeigh *Proportion);
            
            
            CGFloat tWidth = sStudentVideoViewWidth*Proportion;
            CGFloat tHeight = sStudentVideoViewHeigh*Proportion;
            CGFloat tCap = sViewCap *Proportion;
            CGFloat left = tCap;
            for (TKVideoSmallView *view in _iStudentVideoViewArray) {
                
                if (view.iRoomUser) {
                    if (!view.superview) {
                        [_iBottomView addSubview:view];
                    }
                    
                    view.frame = CGRectMake(left, tCap, tWidth, tHeight);
                    left += tCap + tWidth;
                }
                else {
                    
                    if (view.superview) {
                        
                        [view removeFromSuperview];
                    }
                }
                
            }
            
        }
    }
    //我
    {
        
        CGFloat tOurVideoViewHeight = (_iRoomType == RoomType_OneToOne)?sTeacherVideoViewHeigh*Proportion:0;
        _iOurVideoView.frame = CGRectMake(tViewCap,CGRectGetMaxY(_iTeacherVideoView.frame)+tViewCap, tViewWidth, tOurVideoViewHeight);
        _iOurVideoView.hidden = !tOurVideoViewHeight;
        
    }
    
    //静音与奖励
    {
        //非老师
        BOOL tIsHide = (_iUserType != UserType_Teacher) || (![TKEduSessionHandle shareInstance].isClassBegin) || (_iRoomType==RoomType_OneToOne);
        //BOOL tIsHide = (![TKEduSessionHandle shareInstance].isClassBegin) || (_iRoomType==RoomType_OneToOne);
        //BOOL tIsHide = (![TKEduSessionHandle shareInstance].isClassBegin);
        
        // 一对一老师不显示全体静音与奖励按钮
        if (_iRoomType == RoomType_OneToOne && _iUserType == UserType_Teacher) {
            tIsHide = YES;
        }
        
        CGFloat tMuteAudioAndRewardViewHeight = !tIsHide?(40*Proportion):0;
        _iMuteAudioAndRewardView.hidden = tIsHide;
        _iMuteAudioAndRewardView.frame = CGRectMake(tViewCap, CGRectGetMaxY(_iOurVideoView.frame), tViewWidth, tMuteAudioAndRewardViewHeight);
        
        //修改部分
        _iMuteAudioButton.frame = CGRectMake(tViewCap - 10, 0, tViewWidth / 2 - 5, tMuteAudioAndRewardViewHeight);
        _iMuteAudioButton.hidden = tIsHide;
        _iRewardButton.frame = CGRectMake(tViewWidth / 2 - 5 + 10, 0, tViewWidth / 2 - 5, tMuteAudioAndRewardViewHeight);
        //        _iMuteAudioButton.frame = CGRectMake(tViewCap, 0, (tViewWidth-3*tViewCap)/2, tMuteAudioAndRewardViewHeight);
        //        _iMuteAudioButton.hidden = tIsHide;
        //        _iRewardButton.frame = CGRectMake(CGRectGetWidth(_iMuteAudioButton.frame)+tViewCap*2, 0, (tViewWidth-tViewCap*3)/2, tMuteAudioAndRewardViewHeight);
        //        _iMuteAudioButton.hidden = tIsHide;
        
        // 如果是老师，需要管理全体静音按钮的背景色
        if (_iUserType == UserType_Teacher) {
            if ([TKEduSessionHandle shareInstance].isMuteAudio) {
                _iMuteAudioButton.enabled = NO;
                _iMuteAudioButton.backgroundColor = RGBACOLOR_ClassEnd_Red;
            }else{
                _iMuteAudioButton.enabled = YES;
                _iMuteAudioButton.backgroundColor =  RGBACOLOR_ClassBegin_RedDeep;
            }
            
        }
        
    }
    //举手按钮
    {
        BOOL tIsHide = (![TKEduSessionHandle shareInstance].isClassBegin && (_iUserType == UserType_Student));
        
        CGFloat tClassBeginAndRaiseHandHeight = !tIsHide?(40*Proportion):0;
        
        _iClassBeginAndRaiseHandButton.frame = CGRectMake(tViewCap, CGRectGetMaxY(_iMuteAudioAndRewardView.frame)+tViewCap, tViewWidth, tClassBeginAndRaiseHandHeight);
        
        
        BOOL isNeedSelected =  NO;
        if (_iUserType == UserType_Student) {
            bool tIsRaisHand =  [[[TKEduSessionHandle shareInstance].localUser.properties objectForKey:sRaisehand] boolValue];
            isNeedSelected = _iSessionHandle.localUser.publishState == PublishState_BOTH || _iSessionHandle.localUser.publishState == PublishState_AUDIOONLY || tIsRaisHand;
            if (isNeedSelected) {
                
                [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.RaiseHandCancle") forState:UIControlStateNormal];
                
            }else{
                
                [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.RaiseHand") forState:UIControlStateNormal];
                
            }
            
            // 当学生禁用自己音频时，无法举手
            if ([TKEduSessionHandle shareInstance].localUser.disableAudio == YES) {
                _iIsCanRaiseHandUp = NO;
            } else {
                PublishState tPublishState = [TKEduSessionHandle shareInstance].localUser.publishState;
                if ( tPublishState == PublishState_BOTH || tPublishState == PublishState_AUDIOONLY) {
                    _iIsCanRaiseHandUp = NO;
                    [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.RaiseHand") forState:UIControlStateNormal];
                } else {
                    _iIsCanRaiseHandUp = YES;
                    [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.RaiseHand") forState:UIControlStateNormal];
                }
                //                if (tIsRaisHand) {
                //                    _iIsCanRaiseHandUp = NO;
                //                } else {
                //                    _iIsCanRaiseHandUp = YES;
                //                }
            }
            
            if (_iIsCanRaiseHandUp) {
                _iClassBeginAndRaiseHandButton.backgroundColor = RGBACOLOR_ClassBegin_RedDeep;
            } else {
                _iClassBeginAndRaiseHandButton.backgroundColor = RGBACOLOR_ClassEnd_Red;
            }
            
            _iClassBeginAndRaiseHandButton.enabled = _iIsCanRaiseHandUp;
            // [_iSessionHandle sessionHandleChangeUserProperty:_iSessionHandle.localUser.peerID TellWhom:sTellAll Key:sCandraw Value:@(_iIsCanRaiseHandUp) completion:nil];
            
        } else if (_iUserType == UserType_Teacher) {
            
            isNeedSelected = [TKEduSessionHandle shareInstance].isClassBegin;
            
            if (isNeedSelected)
            {
                if ([_iSessionHandle.roomMgr.companyId isEqualToString:YLB_COMPANYID]) {
                    _iClassBeginAndRaiseHandButton.backgroundColor = RGBACOLOR_ClassEnd_Red;
                    [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.ClassIsOver") forState:UIControlStateNormal];
                } else {
                    _iClassBeginAndRaiseHandButton.backgroundColor = RGBACOLOR_ClassBegin_RedDeep;
                    [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.ClassIsOver") forState:UIControlStateNormal];
                }
                //                if (_iSessionHandle.roomMgr.autoStartClassFlag == YES) {
                //                    _iClassBeginAndRaiseHandButton.backgroundColor = RGBACOLOR_ClassBegin_RedDeep;
                //                    [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.ClassIsOver") forState:UIControlStateNormal];
                //                } else {
                //                    _iClassBeginAndRaiseHandButton.backgroundColor = RGBACOLOR_ClassEnd_Red;
                //                    [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.ClassIsOver") forState:UIControlStateNormal];
                //                }
            } else {
                _iClassBeginAndRaiseHandButton.backgroundColor = RGBACOLOR_ClassBegin_RedDeep;
                [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.ClassBegin") forState:UIControlStateNormal];
            }
        }
        [_iRightView bringSubviewToFront:_iClassBeginAndRaiseHandButton];
        
        CGRect tRect = _iClassBeginAndRaiseHandButton.frame;
        
        _iClassBeginAndRaiseHandButton.hidden = tIsHide;
        
        if ([TKEduSessionHandle shareInstance].iIsClassEnd) {
            _iClassBeginAndRaiseHandButton.hidden = YES;
        }
        TKLog(@"2222_hide:%@, _width:%@, frame:%@+%@+%@+%@",@(tIsHide),@(tClassBeginAndRaiseHandHeight),@(tRect.origin.x),@(tRect.origin.y),@(tRect.size.width),@(tRect.size.height));
        
        
        _iClassBeginAndRaiseHandButton.hidden = YES;
        
    }
    //聊天
    {
        CGFloat tChatHeight       = sRightViewChatBarHeight*Proportion;
        //        CGFloat tChatTableHeight  = CGRectGetHeight(_iRightView.frame)-CGRectGetMaxY(_iClassBeginAndRaiseHandButton.frame)-tChatHeight-tViewCap;
        //
        //        _iChatTableView.frame = CGRectMake(0, CGRectGetMaxY(_iClassBeginAndRaiseHandButton.frame)+tViewCap, CGRectGetWidth(_iRightView.frame), tChatTableHeight);
        
        
#pragma mark - 我更改的
        CGFloat tChatTableHeight  = CGRectGetHeight(_iRightView.frame)-CGRectGetMaxY(_iMuteAudioAndRewardView.frame)-tChatHeight-tViewCap;
        _iChatTableView.frame = CGRectMake(0, CGRectGetMaxY(_iMuteAudioAndRewardView.frame)+tViewCap, CGRectGetWidth(_iRightView.frame), tChatTableHeight);
        
        
        
        
        _inputContainerFrame      = CGRectMake(0, CGRectGetMaxY(_iChatTableView.frame), sRightWidth*Proportion, tChatHeight);
        _inputContainer.frame     = _inputContainerFrame;
        _inputInerContainer.frame =  CGRectMake(0, 0, CGRectGetWidth(_inputContainer.frame), CGRectGetHeight(_inputContainer.frame));
        
        {
            CGFloat tInPutInerContainerWidth = CGRectGetWidth(_inputInerContainer.frame);
            CGFloat tInPutInerContainerHeigh = CGRectGetHeight(_inputInerContainer.frame);
            CGRect rectInputFieldFrame = CGRectMake(0, 0, tInPutInerContainerWidth, tInPutInerContainerHeigh);
            _inputField.frame = rectInputFieldFrame;
            
        }
        {
            CGFloat tInPutInerContainerHeigh = CGRectGetHeight(_inputInerContainer.frame);
            CGFloat tInPutInerContainerWidth = CGRectGetWidth(_inputInerContainer.frame);
            CGRect tReplyTextFrame = CGRectMake(0, 0, tInPutInerContainerWidth, tInPutInerContainerHeigh);
            _replyText.frame = tReplyTextFrame;
            
        }
        {
            
            CGFloat tInPutInerContainerHeigh = CGRectGetHeight(_inputInerContainer.frame);
            CGFloat tSendButtonX = (sRightWidth-sSendButtonWidth-4)*Proportion;
            _sendButton.frame = CGRectMake(tSendButtonX, 4, sSendButtonWidth*Proportion, tInPutInerContainerHeigh-4*2);
            
        }
        
    }
    //导航栏
    {
        if (_iUserType == UserType_Student) {
            _iUserButton.hidden = YES;
            _iMediaButton.hidden = YES;
            _iDocumentButton.hidden = YES;
            
        }
        
        for (RoomUser *tUser in [TKEduSessionHandle shareInstance].userStdntAndTchrArray) {
            BOOL isHaveRasieHandUser = [[tUser.properties objectForKey:sRaisehand]boolValue];
            _iUserButton.selected = isHaveRasieHandUser;
            
        }
        
        
    }
    
    // 判断上下课按钮是否需要隐藏
    if (_iSessionHandle.roomMgr.hideClassBeginEndButton == YES && _iSessionHandle.roomMgr.localUser.role == UserType_Teacher) {
        _iClassBeginAndRaiseHandButton.hidden = YES;
    }
}

-(void)initRightView{
    
    {
        CGFloat tRightY = CGRectGetMaxY(_titleView.frame);
        CGRect tRithtFrame = CGRectMake(ScreenW-sRightWidth*Proportion, tRightY, sRightWidth*Proportion, ScreenH-tRightY);
        
        _iRightView = ({
            
            UIView *tRightView = [[UIView alloc] initWithFrame: tRithtFrame];
            tRightView.backgroundColor =  RGBCOLOR(62, 62, 62) ;
            tRightView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            tRightView;
        });
        [_iScroll addSubview:_iRightView];
        
    }
    CGFloat tViewCap = sViewCap*Proportion;
    //老师
    CGFloat tViewWidth = (sRightWidth-2*sViewCap)*Proportion;
    {
        
        _iTeacherVideoView= ({
            
            TKVideoSmallView *tTeacherVideoView = [[TKVideoSmallView alloc]initWithFrame:CGRectMake(tViewCap, tViewCap, tViewWidth, sTeacherVideoViewHeigh*Proportion) aVideoRole:EVideoRoleTeacher];
            tTeacherVideoView.iPeerId = @"";
            tTeacherVideoView.iVideoViewTag = -1;
            tTeacherVideoView.isNeedFunctionButton = (_iUserType==UserType_Teacher);
            tTeacherVideoView.iEduClassRoomSessionHandle = _iSessionHandle;
            tTeacherVideoView;
            
        });
        [_iRightView addSubview:_iTeacherVideoView];
        
    }
    //我
    {
        
        CGFloat tOurVideoViewHeight = (_iRoomType == RoomType_OneToOne)?sTeacherVideoViewHeigh*Proportion:0;
        _iOurVideoView= ({
            
            TKVideoSmallView *tOurVideoView = [[TKVideoSmallView alloc]initWithFrame:CGRectMake(tViewCap,CGRectGetMaxY(_iTeacherVideoView.frame)+tViewCap, tViewWidth, tOurVideoViewHeight) aVideoRole:EVideoRoleOur];
            tOurVideoView.iPeerId = @"";
            tOurVideoView.iEduClassRoomSessionHandle = _iSessionHandle;
            tOurVideoView.iVideoViewTag = -2;
            tOurVideoView.isNeedFunctionButton = (_iUserType==UserType_Teacher);
            tOurVideoView;
            
        });
        [_iRightView addSubview:_iOurVideoView];
        _iOurVideoView.hidden = !tOurVideoViewHeight;
        
        
    }
    
    //静音与奖励
    {
        //不是老师，或没上课，隐藏 有1为1
        BOOL tIsHide = (_iUserType != UserType_Teacher) || (![TKEduSessionHandle shareInstance].isClassBegin)|| (_iRoomType==RoomType_OneToOne);
        CGFloat tMuteAudioAndRewardViewHeight = !tIsHide?(40*Proportion):0;
        
        _iMuteAudioAndRewardView = ({
            
            UIView *tView = [[UIView alloc]initWithFrame:CGRectMake(tViewCap, CGRectGetMaxY(_iOurVideoView.frame), tViewWidth, tMuteAudioAndRewardViewHeight)];
            //tView.backgroundColor = [UIColor yellowColor];
            tView;
            
            
        });
        _iMuteAudioAndRewardView.hidden = tIsHide;
        
        _iMuteAudioButton = ({
            UIButton *tButton = [[UIButton alloc]initWithFrame:CGRectMake(tViewCap, 0, tViewWidth / 2 - 5, (40*Proportion))];
            tButton.titleLabel.font = TKFont(13);
            [tButton addTarget:self action:@selector(muteAduoButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            
            if (_iUserType == UserType_Student) {
                [tButton setTitle:MTLocalized(@"Button.CloseAudio") forState:UIControlStateNormal];
                [tButton setTitle:MTLocalized(@"Button.OpenAudio") forState:UIControlStateSelected];
                tButton.backgroundColor = RGBACOLOR_ClassBegin_RedDeep;
            } else {
                [tButton setTitle:MTLocalized(@"Button.MuteAudio") forState:UIControlStateNormal];
                tButton.backgroundColor = RGBACOLOR_ClassBegin_RedDeep;
            }
            
            [TKUtil setCornerForView:tButton];
            [tButton setTitleColor:RGBCOLOR(255, 255, 255) forState:UIControlStateNormal];
            tButton;
            
        });
        
        [_iMuteAudioAndRewardView addSubview:_iMuteAudioButton];
        
        _iRewardButton = ({
            UIButton *tButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetWidth(_iMuteAudioButton.frame)+tViewCap*2, 0, tViewWidth / 2 - 5, (40*Proportion))];
            tButton.titleLabel.font = TKFont(13);
            
            // [tButton button_exchangeImplementations];
            
            [tButton addTarget:self action:@selector(rewardButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            
            if (_iUserType == UserType_Student) {
                [tButton setTitle:MTLocalized(@"Button.CloseVideo") forState:UIControlStateNormal];
                [tButton setTitle:MTLocalized(@"Button.OpenVideo") forState:UIControlStateSelected];
            } else {
                tButton.itk_acceptEventInterval = 2;
                [tButton setTitle:MTLocalized(@"Button.Reward") forState:UIControlStateNormal];
            }
            
            [TKUtil setCornerForView:tButton];
            tButton.backgroundColor = RGBCOLOR(81,104, 204);
            [tButton setTitleColor:RGBCOLOR(255, 255, 255) forState:UIControlStateNormal];
            tButton;
            
        });
        [_iMuteAudioAndRewardView addSubview:_iRewardButton];
        [_iRightView addSubview:_iMuteAudioAndRewardView];
    }
    //举手按钮
    {
        //学生且没上课状态，隐藏，否则不隐藏
        
        BOOL tIsHide = (![TKEduSessionHandle shareInstance].isClassBegin && (_iUserType == UserType_Student));
        
        
        CGFloat tClassBeginAndRaiseHeight =  40*Proportion;
        _iClassBeginAndRaiseHandButton = ({
            
            UIButton *tButton = [[UIButton alloc]initWithFrame:CGRectMake(tViewCap, CGRectGetMaxY(_iMuteAudioAndRewardView.frame)+tViewCap, tViewWidth, tClassBeginAndRaiseHeight)];
            if (_iUserType == UserType_Student) {
                [tButton setTitle:MTLocalized(@"Button.RaiseHand") forState:UIControlStateNormal];
                
                
            }else{
                [tButton setTitle:MTLocalized(@"Button.ClassBegin") forState:UIControlStateNormal];
            }
            [tButton addTarget:self action:@selector(classBeginAndRaiseHandButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            [tButton setTitleColor:RGBCOLOR(255, 255, 255) forState:UIControlStateNormal];
            tButton.titleLabel.font = TKFont(15);
            
            [tButton setBackgroundColor:RGBCOLOR(207, 65, 21)];
            [TKUtil setCornerForView:tButton];
            
            tButton.hidden = YES;
            
            
            tButton;
            
            
        });
        //todo
        
        if (_iSessionHandle.localUser.role == UserType_Student) {
            [TKUtil setHeight:_iClassBeginAndRaiseHandButton To:0];
        }
        
        _iClassBeginAndRaiseHandButton.hidden = tIsHide;
        CGRect tRect = _iClassBeginAndRaiseHandButton.frame;
        
        TKLog(@"11111_hide:%@, _width:%@, frame:%@+%@+%@+%@",@(tIsHide),@(tClassBeginAndRaiseHeight),@(tRect.origin.x),@(tRect.origin.y),@(tRect.size.width),@(tRect.size.height));
        [_iRightView addSubview:_iClassBeginAndRaiseHandButton];
        
        
        
    }
    //聊天
    {
        CGFloat tChatHeight       = sRightViewChatBarHeight*Proportion;
        
        //        CGFloat tChatTableHeight  = CGRectGetHeight(_iRightView.frame)-CGRectGetMaxY(_iClassBeginAndRaiseHandButton.frame)-tChatHeight-tViewCap;
        //        _iChatTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(_iClassBeginAndRaiseHandButton.frame)+tViewCap, CGRectGetWidth(_iRightView.frame), tChatTableHeight) style:UITableViewStylePlain];
        
        
#pragma mark - 修改的
        CGFloat tChatTableHeight  = CGRectGetHeight(_iRightView.frame)-CGRectGetMaxY(_iMuteAudioAndRewardView.frame)-tChatHeight-tViewCap;
        _iChatTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(_iMuteAudioAndRewardView.frame)+tViewCap, CGRectGetWidth(_iRightView.frame), tChatTableHeight) style:UITableViewStylePlain];
        
        
        
        _iChatTableView.backgroundColor = [UIColor clearColor];
        _iChatTableView.separatorColor  = [UIColor clearColor];
        _iChatTableView.showsHorizontalScrollIndicator = NO;
        
        _iChatTableView.delegate   = self;
        _iChatTableView.dataSource = self;
        _iChatTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        
        [_iChatTableView registerClass:[TKMessageTableViewCell class] forCellReuseIdentifier:sMessageCellIdentifier];
        [_iChatTableView registerClass:[TKStudentMessageTableViewCell class] forCellReuseIdentifier:sStudentCellIdentifier];
        [_iChatTableView registerClass:[TKTeacherMessageTableViewCell class] forCellReuseIdentifier:sDefaultCellIdentifier];
        [_iRightView addSubview:_iChatTableView];
        
        
        _inputContainerFrame = CGRectMake(0, CGRectGetMaxY(_iChatTableView.frame), sRightWidth*Proportion, tChatHeight);
        _inputContainer  = ({
            
            TGInputToolBarView *tTollBarView =  [[TGInputToolBarView alloc] initWithFrame:_inputContainerFrame];
            tTollBarView.backgroundColor       = RGBCOLOR(62,62,62);
            //tTollBarView.layer.backgroundColor = RGBCOLOR(247,247,247).CGColor;
            tTollBarView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
            tTollBarView;
            
        });
        
        [_iRightView addSubview:_inputContainer];
        _iChatView = [[TKChatView alloc]init];
        UIButton *tButton = ({
            
            CGRect tInPutInerContainerRect = CGRectMake(1, 1, CGRectGetWidth(_inputContainer.frame)-1, CGRectGetHeight(_inputContainer.frame)-1);
            UIButton *tSendButton =  [UIButton buttonWithType:UIButtonTypeCustom];
            tSendButton.frame = tInPutInerContainerRect;
            
            [tSendButton setTitle:MTLocalized(@"Say.say") forState:UIControlStateNormal];
            tSendButton.titleLabel.font = TKFont(10);
            tSendButton.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
            [tSendButton addTarget:self action:@selector(replyAction) forControlEvents:UIControlEventTouchUpInside];
            tSendButton;
        });
        [_inputContainer addSubview:tButton];
        
        
#pragma mark - 添加常用语句Button
        self.xc_commonButton = ({
            
            
            UIImage *xc_img = UIIMAGE_FROM_NAME(@"changyongyu_wei");
            CGFloat tSendButtonX = (sRightWidth-xc_img.size.width-4)*Proportion-10;
            UIButton *tSendButton =  [UIButton buttonWithType:UIButtonTypeCustom];
            tSendButton.frame = CGRectMake(tSendButtonX, (tButton.height-xc_img.size.height)/2.0, xc_img.size.width, xc_img.size.height);
            [tSendButton setImage:UIIMAGE_FROM_NAME(@"changyongyu_wei") forState:UIControlStateNormal];
            [tSendButton setImage:UIIMAGE_FROM_NAME(@"chongyongyu_yi") forState:UIControlStateSelected];
            
            tSendButton.titleLabel.font = TKFont(10);
            
#pragma mark - 注销  不然button会移动
            //            tSendButton.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
            
            [tSendButton addTarget:self action:@selector(replyAction2:) forControlEvents:UIControlEventTouchUpInside];
            tSendButton;
        });
        [tButton addSubview:self.xc_commonButton];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
    }
    {
        
        _iDocumentListView = [[TKDocumentListView alloc]initWithFrame:CGRectMake(ScreenW, 0, 382, ScreenH)];
        _iMediaListView = [[TKDocumentListView alloc]initWithFrame:CGRectMake(ScreenW, 0, 382, ScreenH)];
        _iMediaListView.delegate = self;
        _iUsertListView = [[TKDocumentListView alloc]initWithFrame:CGRectMake(ScreenW, 0, 382, ScreenH) ];
        [TKEduSessionHandle shareInstance].iMediaListView = _iMediaListView;
        [TKEduSessionHandle shareInstance].iDocumentListView = _iDocumentListView;
        
    }
    
    
}
-(void)initWhiteBoardView{
    
    CGRect tFrame = CGRectMake(0, CGRectGetMaxY(_titleView.frame), ScreenW-sRightWidth*Proportion, CGRectGetHeight(_iRightView.frame)-sBottomViewHeigh*Proportion);
    if (_iRoomType == RoomType_OneToOne) {
        tFrame = CGRectMake(0, CGRectGetMaxY(_titleView.frame), ScreenW-sRightWidth*Proportion, (CGRectGetHeight(_iRightView.frame)));
    }
    TKEduRoomProperty *tClassRoomProperty  = _iRoomProperty;
    
    NSDictionary *tDic = _iParamDic;
    _iTKEduWhiteBoardView = [_iSessionHandle.iBoardHandle createWhiteBoardWithFrame:tFrame UserName:@"" aBloadFinishedBlock:^{
        [TKEduNetManager getGiftinfo:tClassRoomProperty.iRoomId aParticipantId: tClassRoomProperty.iUserId  aHost:tClassRoomProperty.sWebIp aPort:tClassRoomProperty.sWebPort aGetGifInfoComplete:^(id  _Nullable response) {
            dispatch_async(dispatch_get_main_queue(), ^{
#if TARGET_IPHONE_SIMULATOR
                
#else
                
                int result = 0;
                result = [[response objectForKey:@"result"]intValue];
                if (!result || result == -1) {
                    
                    NSArray *tGiftInfoArray = [response objectForKey:@"giftinfo"];
                    int giftnumber = 0;
                    for(int  i = 0; i < [tGiftInfoArray count]; i++) {
                        if (![tClassRoomProperty.iUserId isEqualToString:@"0"] && _iRoomProperty.iUserId) {
                            NSDictionary *tDicInfo = [tGiftInfoArray objectAtIndex: i];
                            if ([[tDicInfo objectForKey:@"receiveid"] isEqualToString:tClassRoomProperty.iUserId]) {
                                
                                giftnumber = [tDicInfo objectForKey:@"giftnumber"] ? [[tDicInfo objectForKey:@"giftnumber"] intValue] : 0;
                                break;
                                
                            }
                        }
                    }
                    
                    [[TKEduSessionHandle shareInstance] joinEduClassRoomWithParam:tDic aProperties:@{sGiftNumber:@(giftnumber)}];
                    
                }
#endif
            });
            
        } aGetGifInfoError:^int(NSError * _Nullable aError) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[TKEduSessionHandle shareInstance] joinEduClassRoomWithParam:tDic aProperties:nil];
            });
            
            return 1;
        }];
    } aRootView:_iScroll];
    
    [_iScroll addSubview:_iTKEduWhiteBoardView];
}

-(void)initBottomView{
    _iBottomView = ({
        
        UIView *tBottomView = [[UIView alloc]initWithFrame:CGRectMake(0, ScreenH - sBottomViewHeigh*Proportion, ScreenW-sRightWidth*Proportion, sBottomViewHeigh *Proportion)];
        tBottomView;
        
    });
    _iBottomView.backgroundColor = RGBCOLOR(48, 48, 48);
    
    [_iScroll addSubview:_iBottomView];
    
    _iStudentVideoViewArray = [NSMutableArray arrayWithCapacity:_iRoomProperty.iMaxVideo.intValue];
    
    CGFloat tWidth = sStudentVideoViewWidth*Proportion;
    CGFloat tHeight = sStudentVideoViewHeigh*Proportion;
    CGFloat tCap = sViewCap *Proportion;
    for (int i = 0; i < _iRoomProperty.iMaxVideo.intValue; ++i) {
        TKVideoSmallView *tOurVideoBottomView = [[TKVideoSmallView alloc]initWithFrame:CGRectMake(tCap*2 + tWidth,tCap, tWidth, tHeight) aVideoRole:EVideoRoleOther];
        tOurVideoBottomView.iPeerId         = @"";
        tOurVideoBottomView.iVideoViewTag   = i;
        tOurVideoBottomView.isNeedFunctionButton = (_iUserType==UserType_Teacher);
        tOurVideoBottomView.iEduClassRoomSessionHandle = _iSessionHandle;
        tOurVideoBottomView.hidden = NO;
        [_iStudentVideoViewArray addObject:tOurVideoBottomView];
    }
    
    _iBottomView.hidden = NO;//(_iRoomType == RoomType_OneToOne);
    //[_iStudentVideoViewArray addObject:_iOurVideoView];
    
}

- (void)createTimer {
    
    if (!_iCheckPlayVideotimer) {
        __weak typeof(self)weekSelf = self;
        _iCheckPlayVideotimer = [[TKTimer alloc]initWithTimeout:0.5 repeat:YES completion:^{
            __strong typeof(self)strongSelf = weekSelf;
            
            [strongSelf checkPlayVideo];
            
            
        } queue:dispatch_get_main_queue()];
        
        [_iCheckPlayVideotimer start];
        
        
    }
    
}
- (void)invalidateTimer {
    if (_iCheckPlayVideotimer) {
        [_iCheckPlayVideotimer invalidate];
        _iCheckPlayVideotimer = nil;
    }
    [self invalidateClassReadyTime];
    [self invalidateClassBeginTime];
}


-(void)checkPlayVideo{
    
    /*
     usr->_properties:
     candraw = 0;
     hasaudio = 1;
     hasvideo = 1;
     nickname = test;
     publishstate = 3;
     role = 0;
     */
    
    BOOL tHaveRaiseHand = NO;
    BOOL tIsMuteAudioState = YES;
    for (RoomUser *usr in [_iSessionHandle userStdntAndTchrArray]) {
        BOOL tBool = [[usr.properties objectForKey:@"raisehand"]boolValue];
        if (tBool && !tHaveRaiseHand) {
            tHaveRaiseHand = YES;
        }
        if ((usr.publishState == PublishState_AUDIOONLY || usr.publishState == PublishState_BOTH) &&usr.role != UserType_Teacher && tIsMuteAudioState) {
            
            tIsMuteAudioState = NO;
        }
        
    }
    
    if (_iUserType == UserType_Teacher) {
        
        if (tIsMuteAudioState) {
            [TKEduSessionHandle shareInstance].isMuteAudio = YES;
            _iMuteAudioButton.enabled = NO;
            _iMuteAudioButton.backgroundColor = RGBACOLOR_ClassEnd_Red;
        }else{
            [TKEduSessionHandle shareInstance].isMuteAudio = NO;
            _iMuteAudioButton.enabled = YES;
            _iMuteAudioButton.backgroundColor = RGBACOLOR_ClassBegin_RedDeep;
        }
        
    }
    
    _iUserButton.selected = tHaveRaiseHand;
    
    //TKLog(@"1------checkPlayVideo:%@,%@",tHaveRaiseHand?@"举手":@"取消举手",tIsMuteAudioState?@"静音":@"非静音");
}

-(void)playVideo:(RoomUser*)user {
    
    [_iSessionHandle delUserPlayAudioArray:user];
    
    TKVideoSmallView* viewToSee = nil;
    if (user.role == 0)
        viewToSee = _iTeacherVideoView;
    else if (_iRoomType == RoomType_OneToOne) {
        viewToSee = _iOurVideoView;
    }
    else
        for (TKVideoSmallView* view in _iStudentVideoViewArray) {
            if(view.iRoomUser != nil && [view.iRoomUser.peerID isEqualToString:user.peerID]) {
                viewToSee = nil;
                break;
            }
            else if(view.iRoomUser == nil && !viewToSee) {
                viewToSee = view;
            }
        }
    
    if (viewToSee && viewToSee.iRoomUser == nil) {
        
        [self myPlayVideo:user aVideoView:viewToSee completion:^(NSError *error) {
            if (!error) {
                [self refreshUI];
            }
        }];
    }
}

-(void)unPlayVideo:(RoomUser*)user {
    TKVideoSmallView* viewToSee = nil;
    if (user.role == 0)
        viewToSee = _iTeacherVideoView;
    else if (_iRoomType == RoomType_OneToOne) {
        viewToSee = _iOurVideoView;
    }
    else
        for (TKVideoSmallView* view in _iStudentVideoViewArray) {
            if(view.iRoomUser != nil && [view.iRoomUser.peerID isEqualToString:user.peerID]) {
                viewToSee = view;
                break;
            }
        }
    
    if (viewToSee && viewToSee.iRoomUser != nil && [viewToSee.iRoomUser.peerID isEqualToString:user.peerID]) {
        
        [self myUnPlayVideo:user aVideoView:viewToSee completion:^(NSError *error) {
            
            [self refreshUI];
            
        }];
    }
    [_iSessionHandle delePendingUser:user];
}

-(void)replayVideo:(RoomUser*)user {
    TKLog(@"tlm---------- 重新订阅 %@", user.nickName);
    TKVideoSmallView* viewToSee = nil;
    if (user.role == 0) {
        viewToSee = _iTeacherVideoView;
    }
    else if (_iRoomType == RoomType_OneToOne) {
        viewToSee = _iOurVideoView;
    }
    else {
        for (TKVideoSmallView* view in _iStudentVideoViewArray) {
            if(view.iRoomUser != nil && [view.iRoomUser.peerID isEqualToString:user.peerID]) {
                viewToSee = view;
                break;
            }
        }
    }
    
    if (viewToSee && viewToSee.iRoomUser != nil && [viewToSee.iRoomUser.peerID isEqualToString:user.peerID]) {
        [viewToSee clearVideoData];
        [self myPlayVideo:user aVideoView:viewToSee completion:nil];
    }
}

-(void)myUnPlayVideo:(RoomUser*)aRoomUser aVideoView:(TKVideoSmallView*)aVideoView completion:(void (^)(NSError *error))completion{
    [_iSessionHandle sessionHandleUnPlayVideo:aRoomUser.peerID completion:^(NSError *error) {
        //更新uiview
        [aVideoView clearVideoData];
        TKLog(@"----unplay:%@ aVideoView.iPeerId:%@ frame:%@ VideoView:%@",aRoomUser.nickName,aRoomUser.peerID,@(aVideoView.frame.size.width),@(aVideoView.iVideoViewTag));
        completion(error);
        
    }];
}
-(void)myPlayVideo:(RoomUser*)aRoomUser aVideoView:(TKVideoSmallView*)aVideoView completion:(void (^)(NSError *error))completion{
    
    TKLog(@"----play:%@ aVideoView.iPeerId:%@ frame:%@ VideoView:%@",aRoomUser.nickName,aRoomUser.peerID,@(aVideoView.frame.size.width),@(aVideoView.iVideoViewTag));
    [_iSessionHandle sessionHandlePlayVideo:aRoomUser.peerID completion:^(NSError *error, NSObject *view) {
        
        UIView *tView             = (UIView *)view;
        aVideoView.iPeerId        = aRoomUser.peerID;
        aVideoView.iRoomUser      = aRoomUser;
        aVideoView.iRealVideoView = tView;
        tView.frame = CGRectMake(0, 0, CGRectGetWidth(aVideoView.iVideoFrame), CGRectGetHeight(aVideoView.iVideoFrame));
        [aVideoView addVideoView:tView];
        [aVideoView changeAudioDisabledState]; // 当用户初始播放时，没有发送属性改变的通知，需要手动设置
        [aVideoView changeVideoDisabledState]; // 当用户初始播放时，没有发送属性改变的通知，需要手动设置
        if ([aRoomUser.peerID isEqualToString:_iSessionHandle.localUser.peerID]) {
            [aVideoView changeName:[NSString stringWithFormat:@"%@(%@)",aRoomUser.nickName,MTLocalized(@"Role.Me")]];
        }else if (aRoomUser.role == UserType_Teacher){
            [aVideoView changeName:[NSString stringWithFormat:@"%@(%@)",aRoomUser.nickName,MTLocalized(@"Role.Teacher")]];
        }else{
            [aVideoView changeName:aRoomUser.nickName];
        }
        TKLog(@"----play:%@  playerID:%@ frame:%@ VideoView:%@",aRoomUser.nickName, aVideoView.iPeerId,@(tView.frame.size.width),@(aVideoView.iVideoViewTag));
        completion(error);
        
    }];
    
}

-(void)initTapGesTureRecognizer{
    UITapGestureRecognizer* tapTableGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTable:)];
    tapTableGesture.delegate = self;
    [_iScroll addGestureRecognizer:tapTableGesture];
}

-(void)leftButtonPress{
    
    [self tapTable:nil];
    
    
    UIAlertController *alter = [UIAlertController alertControllerWithTitle:MTLocalized(@"Prompt.prompt") message:MTLocalized(@"Prompt.Quite") preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *tActionSure = [UIAlertAction actionWithTitle:MTLocalized(@"Prompt.OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self prepareForLeave:YES];
    }];
    UIAlertAction *tActionCancel = [UIAlertAction actionWithTitle:MTLocalized(@"Prompt.Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alter addAction:tActionSure];
    [alter addAction:tActionCancel];
    
    [self presentViewController:alter animated:YES completion:nil];
    
    
    
}

//如果是自己退出，则先掉leftroom。否则，直接退出。
-(void)prepareForLeave:(BOOL)aQuityourself
{
    [self tapTable:nil];
    
    if (_connectTimer) {
        [_connectTimer invalidate];
        _connectTimer = nil;
    }
    if (_connectHUD) {
        [_connectHUD hide:YES];
        _connectHUD = nil;
    }
    [self invalidateTimer];
    [[UIDevice currentDevice] setProximityMonitoringEnabled: NO]; //建议在播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    [_iAFNetworkReachablitityManager stopMonitoring];
    
    if ([UIApplication sharedApplication].statusBarHidden) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [[UIApplication sharedApplication]
         setStatusBarHidden:NO
         withAnimation:UIStatusBarAnimationNone];
        
#pragma clang diagnostic pop
        
    }
    // _iNetStatus = aQuityourself;
    if (aQuityourself) {
        [_iSessionHandle.iBoardHandle clearAllWhiteBoardData];
        [_iSessionHandle sessionHandleLeaveRoom:nil];
        [_iSessionHandle.iBoardHandle cleanup];
    }else{
        
        [_iSessionHandle clearAllClassData];
        _iSessionHandle.roomMgr = nil;
        _iSessionHandle = nil;
        [_iSessionHandle.iBoardHandle clearAllWhiteBoardData];
        //          [_iTKEduWhiteBoardHandle cleanup];
        //         _iTKEduWhiteBoardHandle = nil;
        dispatch_block_t blk = ^
        {
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:sTKRoomViewControllerDisappear object:nil];
        };
        blk();
    }
    
    _iSessionHandle.iIsClassEnd = NO;
    
    
}

#pragma mark TKEduSessionDelegate

// 获取礼物数
- (void)sessionManagerGetGiftNumber:(void(^)())completion {
    
    // 老师断线重连不需要获取礼物
    if (_iSessionHandle.localUser.role == UserType_Teacher || _iSessionHandle.localUser.role == UserType_Assistant) {
        if (completion) {
            completion();
        }
        return;
    }
    
    // 学生断线重连需要获取礼物
    [TKEduNetManager getGiftinfo:_iRoomProperty.iRoomId aParticipantId: _iRoomProperty.iUserId  aHost:_iRoomProperty.sWebIp aPort:_iRoomProperty.sWebPort aGetGifInfoComplete:^(id  _Nullable response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            int result = 0;
            result = [[response objectForKey:@"result"]intValue];
            if (!result || result == -1) {
                
                NSArray *tGiftInfoArray = [response objectForKey:@"giftinfo"];
                int giftnumber = 0;
                for(int  i = 0; i < [tGiftInfoArray count]; i++) {
                    if (![_iRoomProperty.iUserId isEqualToString:@"0"] && _iRoomProperty.iUserId) {
                        NSDictionary *tDicInfo = [tGiftInfoArray objectAtIndex: i];
                        if ([[tDicInfo objectForKey:@"receiveid"] isEqualToString:_iRoomProperty.iUserId]) {
                            giftnumber = [tDicInfo objectForKey:@"giftnumber"] ? [[tDicInfo objectForKey:@"giftnumber"] intValue] : 0;
                            break;
                        }
                    }
                }
                
                self.iSessionHandle.localUser.properties[sGiftNumber] = @(giftnumber);
                
                if (completion) {
                    completion();
                }
                
                //[[TKEduSessionHandle shareInstance] joinEduClassRoomWithParam:_iParamDic aProperties:@{sGiftNumber:@(giftnumber)}];
            }
        });
        
    } aGetGifInfoError:^int(NSError * _Nullable aError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (completion) {
                completion();
            }
            
            //[[TKEduSessionHandle shareInstance] joinEduClassRoomWithParam:_iParamDic aProperties:nil];
        });
        return 1;
    }];
    
}

//自己进入课堂
- (void)sessionManagerRoomJoined:(NSError *)error {
    
    self.errorOccured = NO;
    
    TKLog(@"jin------myjoined:error:%@",error);
    _iNetConnectionStatus = NO;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES]; //建议在播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
    //  [[NSNotificationCenter defaultCenter] addObserver:self
    //  selector:@selector(proximityStateDidChange:)
    //  name:UIDeviceProximityStateDidChangeNotification object:nil];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    _iTKEduWhiteBoardView.hidden = NO;
    _iNetStatus      = YES;
    _iReconnectCount = 0;
    _iRoomType       = _iSessionHandle.roomType;
    _iUserType       = _iSessionHandle.localUser.role;
    _iRoomProperty.iUserType = _iUserType;
    
    _iRoomProperty.iRoomType = _iRoomType;
    _iRoomProperty.iRoomName =_iSessionHandle.roomName;
    _iRoomProperty.iRoomId   = [_iSessionHandle.roomProperties objectForKey:@"serial"];
    _iRoomProperty.iUserId   = _iSessionHandle.localUser.peerID;
    
    NSString* endtime = [_iSessionHandle.roomProperties objectForKey:@"newendtime"];
    
    if (endtime && [endtime isKindOfClass:[NSString class]] && endtime.length > 0)
    {
        static NSDateFormatter *dateFormatter = nil;
        static dispatch_once_t onceTokendefaultFormatter;
        dispatch_once(&onceTokendefaultFormatter, ^{
            dateFormatter = [[NSDateFormatter alloc]init];
        });
        
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *date = [dateFormatter dateFromString:endtime];
        _iRoomProperty.iEndTime = [date timeIntervalSince1970];
    }
    else{
        _iRoomProperty.iEndTime  = 0;
    }
    NSString* starttime = [_iSessionHandle.roomProperties objectForKey:@"newstarttime"];
    if (starttime && [starttime isKindOfClass:[NSString class]] && starttime.length > 0)
    {
        static NSDateFormatter *dateFormatter = nil;
        static dispatch_once_t onceTokendefaultFormatter;
        dispatch_once(&onceTokendefaultFormatter, ^{
            dateFormatter = [[NSDateFormatter alloc]init];
        });
        
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *date = [dateFormatter dateFromString:starttime];
        _iRoomProperty.iStartTime = [date timeIntervalSince1970];
    }
    else{
        _iRoomProperty.iStartTime  = 0;
    }
    _iRoomProperty.iCurrentTime = [[NSDate date]timeIntervalSince1970];
    
    
    NSAttributedString * attrStr =  [[NSAttributedString alloc]initWithData:[_iSessionHandle.roomName dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)} documentAttributes:nil error:nil];
    
    _titleLable.text =  attrStr.string;
    // _iGiftCount = [[_iSessionHandle.localUser.properties objectForKey:sGiftNumber]integerValue];
    BOOL meHasVideo = _iSessionHandle.localUser.hasVideo;
    BOOL meHasAudio = _iSessionHandle.localUser.hasAudio;
    //    [_iSessionHandle sessionHandleUseLoudSpeaker:NO];
    
    if (_connectHUD) {
        [_connectHUD hide:YES];
        _connectHUD = nil;
    }
    if (self.iReconnectTimeOutTimer) {
        [self.iReconnectTimeOutTimer invalidate];
    }
    //断线重连的timer
    if (_connectTimer) {
        [_connectTimer invalidate];
        _connectTimer = nil;
    }
    if(!meHasVideo){
        //        RoomClient.getInstance().warning(1);
        TKLog(@"没有视频");
    }
    if(!meHasAudio){
        //        RoomClient.getInstance().warning(2);
        TKLog(@"没有音频");
    }
    
    if ([_iSessionHandle.localUser.nickName isEqualToString:@"student"]) {
        _iSessionHandle.localUser.nickName = @"Student";
    }
    
    
    [_iSessionHandle addUserStdntAndTchr:_iSessionHandle.localUser];
    [[TKEduSessionHandle shareInstance]addUser:_iSessionHandle.localUser];
    [self refreshData];
    [self configureHUD:@"" aIsShow:NO];
    
    TKLog(@"tlm----- 课堂加载完成时间: %@", [TKUtil currentTimeToSeconds]);
    
    [_iSessionHandle.iBoardHandle setPageParameterForPhoneForRole:_iUserType];
    
    
    // 非自动上课房间需要上课定时器
    if ([_iSessionHandle.roomMgr.companyId isEqualToString:YLB_COMPANYID]) {
        [self startClassReadyTimer];
    }
    
    [_iSessionHandle sessionHandlePubMsg:sUpdateTime ID:sUpdateTime To:_iSessionHandle.localUser.peerID Data:@"" Save:NO completion:nil];
    
    // 判断上下课按钮是否需要隐藏
    if (_iSessionHandle.roomMgr.hideClassBeginEndButton == YES && _iSessionHandle.roomMgr.localUser.role == UserType_Teacher) {
        _iClassBeginAndRaiseHandButton.hidden = YES;
    }
    
    // 计算课堂结束时间
    expireSeconds = (int)_iRoomProperty.iEndTime + 300;
    
#pragma mark - 是否是自动上课
    if (_iSessionHandle.roomMgr.autoStartClassFlag == YES && _iSessionHandle.isClassBegin == NO && _iSessionHandle.localUser.role == UserType_Teacher && ![_iSessionHandle.roomMgr.companyId isEqualToString:YLB_COMPANYID]) {
        __weak typeof(self)weakSelf = self;
        [TKEduNetManager classBeginStar:[TKEduSessionHandle shareInstance].iRoomProperties.iRoomId companyid:[TKEduSessionHandle shareInstance].iRoomProperties.iCompanyID aHost:[TKEduSessionHandle shareInstance].iRoomProperties.sWebIp aPort:[TKEduSessionHandle shareInstance].iRoomProperties.sWebPort aComplete:^int(id  _Nullable response) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            _iClassBeginAndRaiseHandButton.backgroundColor = RGBACOLOR_ClassEnd_Red;
            [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.ClassIsOver") forState:UIControlStateNormal];
            if ([TKEduSessionHandle shareInstance].iCurrentDocmentModel) {
                [[TKEduSessionHandle shareInstance] publishtDocMentDocModel:[TKEduSessionHandle shareInstance].iCurrentDocmentModel To:sTellAllExpectSender];
            }
            [_iSessionHandle sessionHandlePubMsg:sClassBegin ID:sClassBegin To:sTellAll Data:@{} Save:true completion:nil];
            [strongSelf configureHUD:@"" aIsShow:NO];
            return 0;
        }aNetError:^int(id  _Nullable response) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf configureHUD:@"" aIsShow:NO];
            return 0;
        }];
    }
}
//自己离开课堂
- (void)sessionManagerRoomLeft {
    TKLog(@"-----roomManagerRoomLeft");
    
    [_iSessionHandle configurePlayerRoute:NO isCancle:YES];
    [_iSessionHandle delUserStdntAndTchr:_iSessionHandle.localUser];
    [[TKEduSessionHandle shareInstance]delUser:_iSessionHandle.localUser];
    
    //无网络的状态自动重连
    if (!_iNetStatus) {
        _iSessionHandle.roomMgr = nil;
        _iSessionHandle         = nil;
        [self joinRoomReconnected];
        
    }else{
        [self prepareForLeave:NO];
    }
}



-(void) sessionManagerSelfEvicted{
    
    [self showMessage:MTLocalized(@"KickOut.Repeat")];
    [self prepareForLeave:YES];//NO       // 被踢出后需要离开房间，否则会断线重连
    _iNetStatus = YES;
    TKLog(@"-----SelfEvicted");
    
    
}

//观看视频
- (void)sessionManagerUserPublished:(RoomUser *)user {
    
    [[TKEduSessionHandle shareInstance]addPublishUser:user];
    /// 仝磊鸣修改，原来是大于1，由于现在只发布一次，所以先发布音频后发布视频会看不到
    TKLog(@"jin------publish:%@",user.nickName);
    if (user.publishState >0) {
        
        if (![TKEduSessionHandle shareInstance].isPlayMedia) {
            NSLog(@"---jin sessionManagerUserPublished");
            [[TKEduSessionHandle shareInstance] configurePlayerRoute:NO isCancle:NO];
            
        }
        [self playVideo:user];
    }
    
    if (user.publishState == 1) {
        [_iSessionHandle addOrReplaceUserPlayAudioArray:user];
    }
}
//取消视频
- (void)sessionManagerUserUnpublished:(RoomUser *)user {
    TKLog(@"1------unpublish:%@",user.nickName);
    [_iSessionHandle delUserPlayAudioArray:user];
    [[TKEduSessionHandle shareInstance]delePublishUser:user];
    [[TKEduSessionHandle shareInstance] delePendingUser:user];
    // 如果是用户断网，需要手动修改用户的publishState
    //    for (RoomUser *u in [[TKEduSessionHandle shareInstance] userListExpecPtrlAndTchr]) {
    //        if ([u.peerID isEqualToString:user.peerID]) {
    //            u.publishState = 0;
    //            [self.iUsertListView reloadData];
    //            break;
    //        }
    //    }
    
    [self unPlayVideo:user];
}

//用户进入
- (void)sessionManagerUserJoined:(RoomUser *)user InList:(BOOL)inList {
    
    TKLog(@"1------otherJoined:%@ peerID:%@",user.nickName,user.peerID);
    UserType tMyRole = _iSessionHandle.localUser.role;
    RoomType tRoomType = _iSessionHandle.roomType;
    if (inList) {
        //1 大班课 //0 小班课
        if ((user.role == UserType_Teacher && tMyRole == UserType_Teacher) || (tRoomType == RoomType_OneToOne && user.role == tMyRole)) {
            
            [_iSessionHandle sessionHandleEvictUser:user.peerID completion:nil];
            
        }
        
    }
    
    
    if (tMyRole == UserType_Teacher) {
        NSString* tChairmancontrol = [_iSessionHandle.roomProperties objectForKey:sChairmancontrol];
        NSRange range5 = NSMakeRange(23, 1);
        NSString *str = [tChairmancontrol substringWithRange:range5];
        if ([str integerValue]) {
            
        }
    }
    [[TKEduSessionHandle shareInstance]addUser:user];
    //寻课不提示
    if (user.role !=UserType_Patrol) {
        TKChatMessageModel *tModel = [[TKChatMessageModel alloc]initWithFromid:0 aTouid:0 iMessageType:MessageType_Message aMessage:[NSString stringWithFormat:@"%@ %@",user.nickName, MTLocalized(@"Action.EnterRoom")] aUserName:nil aTime:[TKUtil currentTime]];
        [_iSessionHandle addOrReplaceMessage:tModel];
    }
    BOOL tISpclUser = (user.role !=UserType_Student && user.role !=UserType_Teacher);
    if (tISpclUser) {[[TKEduSessionHandle shareInstance]addSecialUser:user];}
    else {[_iSessionHandle addUserStdntAndTchr:user];}
    [self.iUsertListView reloadData];
    [self refreshData];
    
    
}
//用户离开
- (void)sessionManagerUserLeft:(RoomUser *)user {
    
    TKLog(@"1------otherleft:%@",user.nickName);
    
    [self unPlayVideo:user];
    
    BOOL tIsMe = [[NSString stringWithFormat:@"%@",user.peerID] isEqualToString:[NSString stringWithFormat:@"%@",[TKEduSessionHandle shareInstance].localUser.peerID]];
    if (user.role != UserType_Patrol && !tIsMe) {
        TKChatMessageModel *tModel = [[TKChatMessageModel alloc]initWithFromid:0 aTouid:0 iMessageType:MessageType_Message aMessage:[NSString stringWithFormat:@"%@ %@",user.nickName, MTLocalized(@"Action.ExitRoom")] aUserName:nil aTime:[TKUtil currentTime]];
        [_iSessionHandle addOrReplaceMessage:tModel];
    }
    
    //去掉助教等特殊身份
    BOOL tISpclUser = (user.role !=UserType_Student && user.role !=UserType_Teacher);
    if (tISpclUser)
    {[[TKEduSessionHandle shareInstance]delSecialUser:user];}
    else
    {[_iSessionHandle delUserStdntAndTchr:user];}
    [[TKEduSessionHandle shareInstance] delUser:user];
    [self refreshData];
    
    
}

//用户信息变化
- (void)sessionManagerUserChanged:(RoomUser *)user Properties:(NSDictionary*)properties{
    
    TKLog(@"------UserChanged:%@ properties:(%@)",user.nickName,properties);
    
    NSInteger tGiftNumber = 0;
    if ([properties objectForKey:sGiftNumber]) {
        tGiftNumber = [[properties objectForKey:sGiftNumber]integerValue];
        
        
    }
    
    if ([properties objectForKey:sCandraw] && [_iSessionHandle.localUser.peerID isEqualToString:user.peerID]) {
        _iCandraw         = [[properties objectForKey:sCandraw]boolValue];
        [_iSessionHandle.iBoardHandle setDrawable:_iCandraw];
        
    }
    BOOL isRaiseHand = NO;
    if ([properties objectForKey:sRaisehand]) {
        //如果没做改变的话，就不变化
        NSLog(@"------raiseHand%@",[properties objectForKey:sRaisehand]);
        isRaiseHand  = [[properties objectForKey:sRaisehand]boolValue];
        
        // 当用户状态发生变化，用户列表状态也要发生变化
        for (RoomUser *u in [[TKEduSessionHandle shareInstance] userListExpecPtrlAndTchr]) {
            if ([u.peerID isEqualToString:user.peerID]) {
                [u.properties setValue:@(isRaiseHand) forKey:sRaisehand];
                [self.iUsertListView reloadData];
                break;
            }
        }
    }
    
    if ([properties objectForKey:sPublishstate]) {
        PublishState tPublishState = (PublishState)[[properties objectForKey:sPublishstate]integerValue];
        if([_iSessionHandle.localUser.peerID isEqualToString:user.peerID] ) {
            
            NSLog(@"------sPublishstate%@",[properties objectForKey:sPublishstate]);
            
            if (tPublishState == PublishState_NONE || (tPublishState == PublishState_VIDEOONLY)) {
                _iIsCanRaiseHandUp                = YES;
            } else {
                _iIsCanRaiseHandUp                = NO;
            }
            
            [self refreshUI];
        }
        
        if ((tPublishState == PublishState_VIDEOONLY || tPublishState == PublishState_BOTH) &&
            [[_iSessionHandle userPlayAudioArray] containsObject:user.peerID]) {
            [self playVideo:user];
        }
        
        // 当用户状态发生变化，用户列表状态也要发生变化
        for (RoomUser *u in [[TKEduSessionHandle shareInstance] userListExpecPtrlAndTchr]) {
            if ([u.peerID isEqualToString:user.peerID]) {
                u.publishState = tPublishState;
                [self.iUsertListView reloadData];
                break;
            }
        }
    }
    
    if (_iUserType == UserType_Student && [_iSessionHandle.localUser.peerID isEqualToString:user.peerID]) {
        _iClassBeginAndRaiseHandButton.enabled = _iIsCanRaiseHandUp;
        
        if (isRaiseHand ) {
            [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.RaiseHandCancle") forState:UIControlStateNormal];
        } else {
            [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.RaiseHand") forState:UIControlStateNormal];
        }
        
        if (_iIsCanRaiseHandUp) {
            _iClassBeginAndRaiseHandButton.backgroundColor = RGBACOLOR_ClassBegin_RedDeep;
        } else {
            _iClassBeginAndRaiseHandButton.backgroundColor = RGBACOLOR_ClassEnd_Red;
        }
        
    }
    
    if ([properties objectForKey:sDisableAudio]) {
        // 修改TKEduSessionHandle中iUserList中用户的属性
        for (RoomUser *u in [[TKEduSessionHandle shareInstance] userListExpecPtrlAndTchr]) {
            if ([u.peerID isEqualToString:user.peerID]) {
                u.disableAudio = [[properties objectForKey:sDisableAudio] boolValue];
                [self.iUsertListView reloadData];
                break;
            }
        }
    }
    
    if ([properties objectForKey:sDisableVideo]) {
        for (RoomUser *u in [[TKEduSessionHandle shareInstance] userListExpecPtrlAndTchr]) {
            if ([u.peerID isEqualToString:user.peerID]) {
                u.disableVideo = [[properties objectForKey:sDisableVideo] boolValue];
                [self.iUsertListView reloadData];
                break;
            }
        }
    }
    
    for (RoomUser *user in [[TKEduSessionHandle shareInstance] userListExpecPtrlAndTchr]) {
        NSLog(@"%d", user.disableVideo);
        NSLog(@"%d", user.disableAudio);
    }
    
    NSDictionary *tDic = @{sRaisehand:[properties objectForKey:sRaisehand]?[properties objectForKey:sRaisehand]:@(isRaiseHand),
                           sPublishstate:[properties objectForKey:sPublishstate]?[properties objectForKey:sPublishstate]:@(user.publishState),
                           sCandraw:[properties objectForKey:sCandraw]?[properties objectForKey:sCandraw]:@(user.canDraw),
                           sGiftNumber:@(tGiftNumber),
                           sDisableAudio:[properties objectForKey:sDisableAudio]?@([[properties objectForKey:sDisableAudio] boolValue]):@(user.disableAudio),
                           sDisableVideo:[properties objectForKey:sDisableVideo]?@([[properties objectForKey:sDisableVideo] boolValue]):@(user.disableVideo)
                           };
    [[NSNotificationCenter defaultCenter]postNotificationName:[NSString stringWithFormat:@"%@%@",sRaisehand,user.peerID] object:tDic];
    [[NSNotificationCenter defaultCenter]postNotificationName:sDocListViewNotification object:nil];
    //
    
}
//聊天信息
//- (void)sessionManagerMessageReceived:(NSString *)message ofUser:(RoomUser *)user {
//
//     TKLog(@"------MessageReceived:%@ userName:(%@)",message,user.nickName);
//    NSString *tMyPeerId = _iSessionHandle.localUser.peerID;
//    //自己发送的收不到
//    if (!user) {
//        user = _iSessionHandle.localUser;
//    }
//    BOOL isMe = [user.peerID isEqualToString:tMyPeerId];
//    BOOL isTeacher = user.role == UserType_Teacher?YES:NO;
//    MessageType tMessageType = (isMe)?MessageType_Me:(isTeacher?MessageType_Teacher:MessageType_OtherUer);
//    TKChatMessageModel *tChatMessageModel = [[TKChatMessageModel alloc]initWithFromid:user.peerID aTouid:tMyPeerId iMessageType:tMessageType aMessage:message aUserName:user.nickName aTime:[TKUtil currentTime]];
//
//    [_iSessionHandle addOrReplaceMessage:tChatMessageModel];
//    [self refreshData];
//
//}

- (void)sessionManagerMessageReceived:(NSString *)message ofUser:(RoomUser *)user {
    /*
     
     {
     msg = "\U963f\U9053\U592b";
     type = 0;
     }
     
     */
    NSString *tDataString = [NSString stringWithFormat:@"%@",message];
    NSData *tJsData = [tDataString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary * tDataDic = [NSJSONSerialization JSONObjectWithData:tJsData options:NSJSONReadingMutableContainers error:nil];
    NSNumber *type = [tDataDic objectForKey:@"type"];
    
    // 问题信息不显示
    if ([type integerValue] != 0) {
        return;
    }
    
    NSString *msg = [tDataDic objectForKey:@"msg"];
    TKLog(@"------ type:%@ MessageReceived:%@ userName:(%@)",type,msg,user.nickName);
    NSString *tMyPeerId = _iSessionHandle.localUser.peerID;
    //自己发送的收不到
    if (!user) {
        user = _iSessionHandle.localUser;
    }
    BOOL isMe = [user.peerID isEqualToString:tMyPeerId];
    BOOL isTeacher = user.role == UserType_Teacher?YES:NO;
    MessageType tMessageType = (isMe)?MessageType_Me:(isTeacher?MessageType_Teacher:MessageType_OtherUer);
    TKChatMessageModel *tChatMessageModel = [[TKChatMessageModel alloc]initWithFromid:user.peerID aTouid:tMyPeerId iMessageType:tMessageType aMessage:msg aUserName:user.nickName aTime:[TKUtil currentTime]];
    
    [_iSessionHandle addOrReplaceMessage:tChatMessageModel];
    [self refreshData];
    
}

//进入会议失败
- (void)sessionManagerDidFailWithError:(NSError *)error {
    
    
    
    BOOL isJoinRoomed = YES;
    if (isJoinRoomed) {
        //[self configureHUD:@"" aIsShow:YES];
        [self showConnectHUD];
    }
    
    // 标识发生了断线重连
    self.errorOccured = YES;
    
    if (_iUserType == UserType_Teacher) {
        _iCandraw = YES;
    }else{
        _iSessionHandle.localUser.canDraw = NO;
        _iCandraw = NO;
    }
    
    [_iSessionHandle clearAllClassData];
    [_iSessionHandle.iBoardHandle clearAllWhiteBoardData];
    [_iTeacherVideoView clearVideoData];
    [_iOurVideoView clearVideoData];
    for (TKVideoSmallView *view in _iStudentVideoViewArray) {
        [view clearVideoData];
    }
    // 播放的MP4前，先移除掉上一个MP4窗口
    if (self.iMediaView) {
        [self.iMediaView removeFromSuperview];
        self.iMediaView = nil;
    }
    
    
    
    
    
    //    NSString *tErrorString = error.description;
    //    NSArray *tErrorArray = [[tErrorString lowercaseString]componentsSeparatedByString:@"socket"];
    //    TKLog(@"1------didFailWithError:%@ count :%lu",error,(unsigned long)[tErrorArray count]);
    //    if ([tErrorArray count]>0) {
    //         [self leftRoomAbnormal];
    //         TKLog(@"1------didFailWithErrorSocket2:%@",error);
    //    }
    
}

//相关信令
- (void)sessionManagerOnRemoteMsg:(BOOL)add ID:(NSString*)msgID Name:(NSString*)msgName TS:(unsigned long)ts Data:(NSObject*)data InList:(BOOL)inlist{
    TKLog(@"jin------remoteMsg:%@ msgID:%@",msgName,msgID);
    
    //添加
    if ([msgName isEqualToString:sClassBegin]) {
        
        NSString* tChairmancontrol = [_iSessionHandle.roomProperties objectForKey:sChairmancontrol];
        // NSString *str = [NSString stringWithFormat:@"%@",[tChairmancontrol characterAtIndex:23]];
        NSRange range5 = NSMakeRange(23, 1);
        NSString *str = [tChairmancontrol substringWithRange:range5];;
        NSString *tPeerId = _iSessionHandle.localUser.peerID;
        _iSessionHandle.isClassBegin = add;
        
        //上课
        if (add) {
            
            if ([TKEduSessionHandle shareInstance].isPlayMedia) {
                
                [[TKEduSessionHandle shareInstance]sessionHandleUnpublishMedia:nil];
                
            }
            [self showMessage:MTLocalized(@"Class.Begin")];
            
            if (_iUserType==UserType_Teacher || (_iUserType==UserType_Student && [str intValue]  == 1)) {
                
                [_iSessionHandle sessionHandleChangeUserPublish:tPeerId Publish:(PublishState_BOTH) completion:^(NSError *error) {
                    
                }];
                
            }
            _iClassStartTime = ts;
            bool tIsTeacher  = (_iUserType==UserType_Teacher);
            [_iSessionHandle.iBoardHandle setDrawable:tIsTeacher];
            [_iSessionHandle.iBoardHandle setAddPagePermission:tIsTeacher];
            [_iSessionHandle sessionHandlePubMsg:sUpdateTime ID:sUpdateTime To:tPeerId  Data:data Save:false completion:^(NSError *error) {
                
            }];
            
            [self startClassBeginTimer];
            [self refreshUI];
            
            
        }else{
            
            //下课
            [TKEduSessionHandle shareInstance].iIsClassEnd = YES;
            [self showMessage:MTLocalized(@"Class.Over")];
            [_iSessionHandle sessionHandleChangeUserPublish:tPeerId  Publish:PublishState_NONE completion:^(NSError *error) {
                
            }];
            
            [_iSessionHandle.iBoardHandle setDrawable:false];
            [_iSessionHandle.iBoardHandle setAddPagePermission:false];
            
            [self refreshUI];
            [self invalidateClassBeginTime];
            [self tapTable:nil];
            
            if (![_iSessionHandle.roomMgr.companyId isEqualToString:YLB_COMPANYID]) {
                [self showMessage:MTLocalized(@"Prompt.ClassEnd")];
                [self prepareForLeave:YES];                         // 课程结束离开房间
            }
        }
        
        
    } else if ([msgName isEqualToString:sUpdateTime]) {
        
        if (add) {
            _iServiceTime = ts;
            _iLocalTime   = _iServiceTime - _iClassStartTime;
            _iRoomProperty.iHowMuchTimeServerFasterThenMe = ts - [[NSDate date] timeIntervalSince1970];
            if ([TKEduSessionHandle shareInstance].isClassBegin) {
                if ([_iClassTimetimer isValid]) {
                    //[_iClassTimetimer setFireDate:[NSDate date]];
                } else {
                    _iClassTimetimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                        target:self
                                                                      selector:@selector(onClassTimer)
                                                                      userInfo:nil
                                                                       repeats:YES];
                    [_iClassTimetimer setFireDate:[NSDate date]];
                }
            }
        }
        
    }else if ([msgName isEqualToString:sMuteAudio]){
        
        int tPublishState = _iSessionHandle.localUser.publishState;
        NSString *tPeerId = _iSessionHandle.localUser.peerID;
        [TKEduSessionHandle shareInstance].isMuteAudio = add ?true:false;
        if (tPublishState != PublishState_VIDEOONLY) {
            [_iSessionHandle sessionHandleChangeUserPublish:tPeerId  Publish:(tPublishState)+([TKEduSessionHandle shareInstance].isMuteAudio ?(-PublishState_AUDIOONLY):(PublishState_AUDIOONLY)) completion:^(NSError *error) {
                
            }];
        }else{
            [_iSessionHandle sessionHandleChangeUserPublish:tPeerId  Publish:([TKEduSessionHandle shareInstance].isMuteAudio ?(PublishState_NONE):(PublishState_AUDIOONLY)) completion:^(NSError *error) {
                
            }];
        }
        
        
    }else if ([msgName isEqualToString:sStreamFailure]){
        if ([data isKindOfClass:[NSDictionary class]]) {
            NSDictionary *tDataDic = (NSDictionary *)data;
            NSString *tPeerId = [tDataDic objectForKey:@"studentId"];
            [[TKEduSessionHandle shareInstance] delePendingUser:[[TKEduSessionHandle shareInstance]userInUserList:tPeerId]];
            TKLog(@"-------ICE");
        }
        
    }
    
}


- (void)sessionManagerIceStatusChanged:(NSString*)state ofUser:(RoomUser *)user {
    TKLog(@"------IceStatusChanged:%@ nickName:%@",state,user.nickName);
}

- (void)peerConnectionRecover {
    if (self.errorOccured == NO) {
        PublishState originalState = _iSessionHandle.localUser.publishState;
        [_iSessionHandle sessionHandleChangeUserPublish:_iSessionHandle.localUser.peerID Publish:(PublishState_NONE) completion:nil];
        TKLog(@"tlm---------- 老师PeerConnection Disconnect，先关闭老师视频流");
        [_iSessionHandle sessionHandleChangeUserPublish:_iSessionHandle.localUser.peerID Publish:(originalState) completion:nil];
        TKLog(@"tlm---------- 老师PeerConnection Disconnect，重新发布来恢复");
    }
}

- (void)peerSubscribeRecover:(RoomUser *)user {
    [self replayVideo:user];
}
#pragma mark media

-(void)sessionManagerMediaPublish:(MediaStream *)mediaStream roomUser:(RoomUser *)user{
    [TKEduSessionHandle shareInstance].isPlayMedia = YES;
    [[TKEduSessionHandle shareInstance] configureHUD:@"" aIsShow:NO];
    
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    
    BOOL hasVideo = mediaStream.hasVideo;
    
    NSString *filedId= [NSString stringWithFormat:@"%@",mediaStream.fileid];
    //不是视频的时候
    if (!hasVideo) {
        
        frame =CGRectMake(0, CGRectGetHeight(self.iTKEduWhiteBoardView.frame)-57+CGRectGetMinY(self.iTKEduWhiteBoardView.frame), CGRectGetWidth(self.iTKEduWhiteBoardView.frame), 57);
        if ([TKEduSessionHandle shareInstance].localUser.role == 2) {
            frame =CGRectMake(10, CGRectGetHeight(self.iTKEduWhiteBoardView.frame)-57+CGRectGetMinY(self.iTKEduWhiteBoardView.frame), 57, 57);
        }
    }
    
    // 播放的MP4前，先移除掉上一个MP4窗口
    if (self.iMediaView) {
        [self.iMediaView removeFromSuperview];
        self.iMediaView = nil;
    }
    
    TKBaseMediaView *tMediaView = [[TKBaseMediaView alloc]initWithMediaStream:mediaStream frame:frame];
    _iMediaView = tMediaView;
    
    [self.view addSubview:_iMediaView];
    [[TKEduSessionHandle shareInstance]sessionHandlePlayMedia:filedId completion:^(NSError *error, NSObject *view) {
        UIView *tView = (UIView  *)view;
        tView.frame = tMediaView.frame;
        [tMediaView insertSubview:tView atIndex:0];
    }];
    
    // 设置当前的媒体文档
    for (TKMediaDocModel *mediaModel in _iSessionHandle.mediaArray) {
        if ([[NSString stringWithFormat:@"%@", mediaModel.fileid] isEqualToString:mediaStream.fileid]) {
            [TKEduSessionHandle shareInstance].iCurrentMediaDocModel = mediaModel;
            break;
        }
    }
}


-(void)sessionManagerMediaUnPublish:(MediaStream *)mediaStream roomUser:(RoomUser *)user{
    
    [TKEduSessionHandle shareInstance].isPlayMedia = NO;
    [[TKEduSessionHandle shareInstance] configureHUD:@"" aIsShow:NO];
    [_iMediaView removeFromSuperview];
    _iMediaView = nil;
    if ( [TKEduSessionHandle shareInstance].isChangeMedia) {
        
        [TKEduSessionHandle shareInstance].isChangeMedia = NO;
        TKMediaDocModel *tMediaDocModel =  [TKEduSessionHandle shareInstance].iCurrentMediaDocModel;
        NSString *tNewURLString2 = [TKUtil absolutefileUrl:tMediaDocModel.swfpath webIp:[TKEduSessionHandle shareInstance].iRoomProperties.sWebIp webPort:[TKEduSessionHandle shareInstance].iRoomProperties.sWebPort];
        
        BOOL tIsVideo = [TKUtil isVideo:tMediaDocModel.filetype];
        NSString * toID = [TKEduSessionHandle shareInstance].isClassBegin?sTellAll:[TKEduSessionHandle shareInstance].localUser.peerID;
        
        [[TKEduSessionHandle shareInstance]sessionHandlePublishMedia:tNewURLString2 hasVideo:tIsVideo fileid:[NSString stringWithFormat:@"%@",tMediaDocModel.fileid] filename:tMediaDocModel.filename toID:toID block:nil];
        
    }
    [TKEduSessionHandle shareInstance].iCurrentMediaDocModel = nil;
    
    
}

-(void)sessionManagerUpdateMediaStream:(MediaStream *)mediaStream pos:(NSTimeInterval)pos isPlay:(BOOL)isPlay{
    
    NSTimeInterval duration = mediaStream.duration;
    [_iMediaView updatePlayUI:isPlay];
    if (isPlay) {
        [_iMediaView update:pos total:duration];
    }
    //TKLog(@"jin postion:%@ play:%@",@(pos),@(isPlay));
}

#pragma mark TKEduBoardDelegate

- (void)boardOnFileList:(NSArray*)fileList{
    TKLog(@"------OnFileList:%@ ",fileList);
}
- (BOOL)boardOnRemoteMsg:(BOOL)add ID:(NSString*)msgID Name:(NSString*)msgName TS:(long)ts Data:(NSObject*)data InList:(BOOL)inlist{
    TKLog(@"------WhiteBoardOnRemoteMsg:%@ msgID:%@ ",msgName,msgID);
    return NO;
    
}
- (void)boardOnRemoteMsgList:(NSArray*)list{
    
}
#pragma mark scrollView Delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    
    
#pragma clang diagnostic pop
    
    
}

#pragma mark tableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return 2;
    return _iMessageList.count;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat tHeight = 0;
    TKChatMessageModel *tMessageModel = [_iMessageList objectAtIndex:indexPath.row];
    
    switch (tMessageModel.iMessageType) {
        case MessageType_Message:
        {
            
            CGSize titlesize = [TKMessageTableViewCell sizeFromText:tMessageModel.iMessage withLimitWidth:CGRectGetWidth(_iChatTableView.frame) Font:TKFont(15)];
            tHeight = titlesize.height+20;
            
        }
            break;
            
        case MessageType_OtherUer:
        case MessageType_Teacher:
        case MessageType_Me:
            
        {
            
            CGFloat tViewCap             = 10 *Proportion;
            CGFloat tContentWidth        = CGRectGetWidth(_iChatTableView.frame);
            CGFloat tTimeLabelHeigh      = 16*Proportion;
            CGFloat tTranslateLabelHeigh = 22*Proportion;
            CGSize titlesize = [TKStudentMessageTableViewCell sizeFromText:tMessageModel.iMessage withLimitWidth:tContentWidth-tTranslateLabelHeigh-tViewCap*2 Font:TKFont(15)];;
            CGSize tTranslationSize = [TKStudentMessageTableViewCell sizeFromText:tMessageModel.iTranslationMessage withLimitWidth:tContentWidth-2*tViewCap Font:TKFont(15)];
            
            tHeight = titlesize.height+tTranslationSize.height+20+tTimeLabelHeigh;
            
            //tHeight =100;
            
        }
            break;
        default:
            break;
    }
    
    
    return tHeight + 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    TKChatMessageModel *tMessageModel = [_iMessageList objectAtIndex:indexPath.row];
    
    switch (tMessageModel.iMessageType) {
        case MessageType_Message:
        {
            TKMessageTableViewCell *tCell = [tableView dequeueReusableCellWithIdentifier:sMessageCellIdentifier forIndexPath:indexPath];
            tCell.selectionStyle = UITableViewCellSelectionStyleNone;
            tCell.iMessageText = tMessageModel.iMessage;
            
            [tCell resetView];
            return tCell;
        }
            break;
        case MessageType_OtherUer:
        case MessageType_Teacher:
        case MessageType_Me:
        {
            TKStudentMessageTableViewCell* tCell =[tableView dequeueReusableCellWithIdentifier:sStudentCellIdentifier forIndexPath:indexPath];
            
            tCell.iText               = tMessageModel.iMessage;
            tCell.iMessageLabel.textColor = (tMessageModel.iMessageType ==MessageType_Me)?  RGBCOLOR(221, 221, 221): RGBCOLOR(162, 162, 162);
            tCell.iTranslationtext    = tMessageModel.iTranslationMessage;
            tCell.iTime = tMessageModel.iTime;
            tCell.iNickName = tMessageModel.iUserName;
            tCell.iMessageType        = tMessageModel.iMessageType;
            [tCell resetView];
            //tCell.backgroundColor = [UIColor yellowColor];
            [tCell setSelectionStyle:UITableViewCellSelectionStyleNone];
            return tCell;
            
        }
            break;
            
        default:
            
            break;
    }
    
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:sDefaultCellIdentifier];
    return cell;
    
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    __weak typeof(self)weakSelf = self;
    TKChatMessageModel *tMessageModel = [_iMessageList objectAtIndex:indexPath.row];
    switch (tMessageModel.iMessageType) {
        case MessageType_Message:
        {
            
        }
            break;
        case MessageType_OtherUer:
        case MessageType_Teacher:
        case MessageType_Me:
        {
            
            [TKEduNetManager translation:tMessageModel.iMessage aTranslationComplete:^int(id  _Nullable response, NSString * _Nullable aTranslationString) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                tMessageModel.iTranslationMessage = aTranslationString;
                [_iSessionHandle addOrReplaceMessage:tMessageModel];
                [strongSelf refreshData];
                return 0;
            }];
            
        }
            break;
            
        default:
            
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}
#pragma mark Event

-(void)userButtonClicked:(UIButton*)aButton{
    TKLog(@"用户列表");
    
    NSMutableArray *tUserArray = [[_iSessionHandle userListExpecPtrlAndTchr]mutableCopy];
    [_iUsertListView show:FileListTypeUserList aFileList:tUserArray isClassBegin:[TKEduSessionHandle shareInstance].isClassBegin];
    
}
-(void)mediaButtonClicked:(UIButton *)aButton{
    TKLog(@"影音列表");
    [_iMediaListView show:FileListTypeAudioAndVideo aFileList:[[TKEduSessionHandle shareInstance] mediaArray] isClassBegin:[TKEduSessionHandle shareInstance].isClassBegin];
}
-(void)documentButtonClicked:(UIButton*)aButton{
    TKLog(@"文档列表");
    [_iDocumentListView show:FileListTypeDocument aFileList:[[TKEduSessionHandle shareInstance] docmentArray]isClassBegin:[TKEduSessionHandle shareInstance].isClassBegin];
}


-(void)replyAction
{
    
    [_iChatView show];
}

- (void)replyAction2:(UIButton *)button
{
    button.selected = YES;
    [self.view endEditing:YES];
    [self showPopView:button];
}

- (void)showPopView:(UIButton *)button
{
    //showPopView
    GGT_PopoverController *vc = [GGT_PopoverController new];
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.popoverPresentationController.sourceView = self.xc_commonButton;
    vc.popoverPresentationController.sourceRect = button.bounds;
    vc.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionDown;
    vc.popoverPresentationController.delegate = self;
    
    vc.xc_phraseMuArray = self.xc_phraseMuArray;
    
    // 修改弹出视图的size 在控制器内部修改更好
    //    vc.preferredContentSize = CGSizeMake(100, 100);
    [self presentViewController:vc animated:YES completion:nil];
    
    @weakify(self)
    vc.dismissBlock = ^(NSString *selectString) {
        @strongify(self);
        NSLog(@"点击了---%@", selectString);
        button.selected = NO;
        if ([selectString isKindOfClass:[NSString class]]) {
            if (selectString.length>0) {
                //                [self.room.chatVM sendMessage:selectString];
                _inputField.text = selectString;
                //                [self replyAction];
                
                
                NSDictionary *messageDic = @{@"msg":selectString, @"type":@(0)};
                NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDic options:NSJSONWritingPrettyPrinted error:nil];
                NSString *messageConvertStr = [[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding];
                [[TKEduSessionHandle shareInstance] sessionHandleSendMessage:messageConvertStr completion:nil];
            }
        }
    };
}

#pragma mark - UIPopoverPresentationControllerDelegate
//默认返回的是覆盖整个屏幕，需设置成UIModalPresentationNone。
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller{
    return UIModalPresentationNone;
}

//点击蒙版是否消失，默认为yes；
-(BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController{
    self.xc_commonButton.selected = NO;
    return YES;
}

//弹框消失时调用的方法
-(void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController{
    NSLog(@"弹框已经消失");
}


- (void)refreshData
{
    _iMessageList = [_iSessionHandle messageList];
    
    [_iChatTableView reloadData];
    if(_iChatTableView.contentSize.height > _iChatTableView.frame.size.height)
        [_iChatTableView setContentOffset:CGPointMake(0, _iChatTableView.contentSize.height -_iChatTableView.bounds.size.height) animated:YES];
}
#pragma mark keyboard Notification
- (void)keyboardWillShow:(NSNotification*)notification
{
    
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    // keyboardFrame = [self convertRect:keyboardFrame fromView:nil];
    //会掉两次notification
    if (_knownKeyboardHeight ==  keyboardFrame.size.height) {
        return;
    }
    
    _knownKeyboardHeight = keyboardFrame.size.height;
    double duration = ([[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]);
    [UIView animateWithDuration:duration delay:0.0 options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone) animations:^
     {
         
         [TKUtil setBottom:_inputContainer To: CGRectGetHeight(_iRightView.frame)-_knownKeyboardHeight];
         //如果是举手状态或者已经显示，则直接跳过
         if (_iIsCanRaiseHandUp ) {
             return ;
         }
         
         
     }
                     completion:^(BOOL finished)
     {
         
     }];
    [self changeInputAreaHeight:(int)_knownKeyboardHeight duration:duration orientationChange:false dragging:false completion:nil];
    
}


- (void)keyboardWillHide:(NSNotification *)notification
{
    
    if (_knownKeyboardHeight == 0) {
        return;
    }
    _replyText.hidden = _inputField.text.length != 0;
    
    
    double duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    _knownKeyboardHeight = 0;
    [UIView animateWithDuration:duration delay:0.0 options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone) animations:^
     {
         
         [TKUtil setBottom:_inputContainer To: CGRectGetHeight(_iRightView.frame)-_knownKeyboardHeight];
         //[TKUtil setBottom:_inputContainer To: ScreenH-_knownKeyboardHeight];
         //如果是举手状态或者已经隐藏举手，则跳过
         if (_iIsCanRaiseHandUp) {
             return ;
         }
         
     }
                     completion:^(BOOL finished)
     {
         
     }];
    
    
    [self changeInputAreaHeight:_knownKeyboardHeight duration:duration orientationChange:false dragging:false completion:nil];
}

-(void)reSetTitleView:(BOOL)aIsHide aInputContainerIsHide:(BOOL)aInputContainerIsHide aStatusIsHide:(BOOL)aStatusIsHide{
    _titleView.hidden = aIsHide;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[UIApplication sharedApplication] setStatusBarHidden:aStatusIsHide animated:YES];
    
#pragma clang diagnostic pop
    
    // _inputContainer.hidden = aInputContainerIsHide;
    
}
-(void)chatBegin{
    [_inputField becomeFirstResponder];
}
- (void)changeInputAreaHeight:(int)height duration:(NSTimeInterval)duration orientationChange:(bool)orientationChange dragging:(bool)__unused dragging completion:(void (^)(BOOL finished))completion
{
    
    
    
}
- (void)updatePlaceholderVisibility:(bool)firstResponder
{
    _replyText.hidden = firstResponder || _inputField.text.length != 0;
}
#pragma mark TKTextViewInternalDelegate
- (void)TKTextViewChangedResponderState:(bool)firstResponder
{
    [self updatePlaceholderVisibility:firstResponder];
}
#pragma mark TKGrowingTextViewDelegate
- (void)growingTextView:(TKGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    [self growingTextView:growingTextView willChangeHeight:height animated:true];
}

- (void)growingTextView:(TKGrowingTextView *)__unused growingTextView willChangeHeight:(float)height animated:(bool)animated
{
    CGRect inputContainerFrame = _inputContainer.frame;
    float newHeight = MAX(10 + height, sChatBarHeight);
    if (inputContainerFrame.size.height != newHeight)
    {
        int currentKeyboardHeight = _knownKeyboardHeight;
        inputContainerFrame.size.height = newHeight;
        inputContainerFrame.origin.y = _inputContainer.superview.frame.size.height - currentKeyboardHeight - inputContainerFrame.size.height;
        _inputContainer.frame = inputContainerFrame;
        _replyText.frame = CGRectMake(10, 5, _inputContainer.frame.size.width - 75 , _inputContainer.frame.size.height - 10);
        
        [TKUtil setHeight:_inputInerContainer To:newHeight-2*6];
        
        [TKUtil setHeight:_inputField To:CGRectGetHeight(_inputInerContainer.frame)];
        
        
        
        
    }
}

- (void)growingTextViewDidChange:(TKGrowingTextView *)growingTextView
{
    [self updatePlaceholderVisibility:[growingTextView.internalTextView isFirstResponder]];
}

- (BOOL)growingTextViewShouldReturn:(TKGrowingTextView *)growingTextView
{
    [self replyAction];
    return YES;
}

- (BOOL)growingTextViewShouldBeginEditing:(TKGrowingTextView *)growingTextView
{
    _replyText.hidden = YES;
    return YES;
}
- (BOOL)growingTextViewShouldEndEditing:(TKGrowingTextView *)growingTextView
{
    return YES;
}


#pragma mark UIGestureRecognizerDelegate
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"] || [NSStringFromClass([touch.view class]) isEqualToString:@"TKTextViewInternal"] ||  [NSStringFromClass([touch.view class]) isEqualToString:@"UIButton"] )
    {
        return NO;
    }
    else
    {
        
        [self tapTable:nil];
        return !_iCandraw;
        
    }
    
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return true;
}

- (void)tapTable:(UIGestureRecognizer *)gesture
{
    
    [_inputField resignFirstResponder];
    [_iDocumentListView hide];
    [_iUsertListView hide];
    [_iMediaListView hide];
    [_iTeacherVideoView hideFunctionView];
    [_iOurVideoView hideFunctionView];
    
    for (TKVideoSmallView * view in _iStudentVideoViewArray) {
        [view hideFunctionView];
    }
    
    //[self resetTimer];
    //[self moveNaviBar];
}
#pragma mark reconnect
-(void)sessionHandleReconnected:(id)params{
    [self showConnectHUD];
    [self clearDataForReconnectFail];
}
-(void)leftRoomAbnormal{
    _iNetStatus = NO;
    if (_iSessionHandle) {
        TKLog(@"没有网络-------------------调用离开教室，设置断网超时");
        [self showConnectHUD];
        [_iSessionHandle sessionHandleLeaveRoom:YES Completion:nil];
        
    }
    
}

-(void)joinRoomReconnected{
    
    //如果是无网状态，则进行重连
    
    
    if (self.connectTimer) {
        [self.connectTimer invalidate];
        self.connectTimer = nil;
    }
    
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                         target:self
                                                       selector:@selector(reconnectMeeting)
                                                       userInfo:nil
                                                        repeats:NO];
    [self.connectTimer fire];
    
    
}
-(void)clear{
    _iSessionHandle.roomMgr = nil;
    _iSessionHandle         = nil;
    [self joinRoomReconnected];
}
//重连
-(void)reconnectMeeting{
    //如果不是正在退出且不是有网，则重连。
    //if (_iSessionHandle || self.iNetStatus){return;}
    if (self.iNetStatus){return;}
    if (_iReconnectTimeOutTimer) {
        [_iReconnectTimeOutTimer invalidate];
        _iReconnectTimeOutTimer = nil;
    }
    //断网超过60 退出会议
    _iReconnectTimeOutTimer = [[TKTimer alloc]initWithTimeout:60 repeat:NO completion:^{
        if (_connectHUD) {
            [_connectHUD hide:YES];
            _connectHUD = nil;
        }
        [self prepareForLeave:NO];
        
        
    } queue:dispatch_get_main_queue()];
    [self.iReconnectTimeOutTimer start];
    
    [self showConnectHUD];
    [self clearDataForReconnectFail];
    _iReconnectCount +=1;
    if (!_iSessionHandle) {
        
        _iSessionHandle = [TKEduSessionHandle shareInstance];
        [_iSessionHandle configureSession:_iParamDic aRoomDelegate:_iRoomDelegate aSessionDelegate:self aBoardDelegate:self aRoomProperties:_iRoomProperty];
        
    }
    UIView *tView = _iTKEduWhiteBoardView;
    
    [self initWhiteBoardView];
    [tView removeFromSuperview];
    tView = nil;
    TKLog(@"----_connectTimer%@ count:%@ tkEduClassRoomSessionHandle:%@",_connectTimer,@(_iReconnectCount),_iSessionHandle);
}


- (void)showConnectHUD
{
    if (!_connectHUD) {
        _connectHUD = [[TKProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
        [[UIApplication sharedApplication].keyWindow addSubview:_connectHUD];
        _connectHUD.dimBackground             = YES;
        _connectHUD.removeFromSuperViewOnHide = YES;
    }
    _connectHUD.labelText                 = MTLocalized(@"State.Reconnecting");
    [_connectHUD show:YES];
    
}
- (void)clearDataForReconnectFail{
    
    if (_iUserType == UserType_Teacher) {
        _iCandraw = YES;
    }else{
        _iCandraw = NO;
    }
    
    [_iSessionHandle clearAllClassData];
    [_iSessionHandle.iBoardHandle clearAllWhiteBoardData];
    [_iTeacherVideoView clearVideoData];
    [_iOurVideoView clearVideoData];
    for (TKVideoSmallView *view in _iStudentVideoViewArray) {
        [view clearVideoData];
    }
    [_iStudentVideoViewArray removeAllObjects];
}

#pragma mark 横竖屏
-(BOOL)shouldAutorotate{
    return NO;
}
-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscapeRight ;
}
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationLandscapeRight;
}
#pragma mark 状态栏
//设置样式
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

//设置是否隐藏
- (BOOL)prefersStatusBarHidden {
    return NO;
}

//设置隐藏动画
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}
#pragma mark 其他
- (void)showMessage:(NSString *)message {
    NSArray *array = [UIApplication sharedApplication].windows;
    int count = (int)array.count;
    [TKRCGlobalConfig HUDShowMessage:message addedToView:[array objectAtIndex:(count >= 2 ? (count - 2) : 0)] showTime:2];
}
#pragma mark 声音
- (void)handleAudioSessionInterruption:(NSNotification*)notification {
    
    NSNumber *interruptionType = [[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey];
    NSNumber *interruptionOption = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
    
    switch (interruptionType.unsignedIntegerValue) {
        case AVAudioSessionInterruptionTypeBegan:{
            // • Audio has stopped, already inactive
            // • Change state of UI, etc., to reflect non-playing state
        } break;
        case AVAudioSessionInterruptionTypeEnded:{
            // • Make session active
            // • Update user interface
            // • AVAudioSessionInterruptionOptionShouldResume option
            if (interruptionOption.unsignedIntegerValue == AVAudioSessionInterruptionOptionShouldResume) {
                // Here you should continue playback.
                //[player play];
            }
        } break;
        default:
            break;
    }
    AVAudioSessionInterruptionType type = [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue];
    TKLog(@"---jin 当前category: 打断 %@",@(type));
}


-(void)handleMediaServicesReset:(NSNotification *)aNotification{
    
    
    
    AVAudioSessionInterruptionType type = [aNotification.userInfo[AVAudioSessionInterruptionTypeKey] intValue];
    TKLog(@"---jin 当前AVAudioSessionMediaServicesWereResetNotification: 打断 %@",@(type));
    
    
    
}
- (void)routeChange:(NSNotification*)notify{
    if(notify){
        
        if (([AVAudioSession sharedInstance].categoryOptions !=AVAudioSessionCategoryOptionMixWithOthers )||([AVAudioSession sharedInstance].category !=AVAudioSessionCategoryPlayAndRecord) ) {
            //[[TKEduSessionHandle shareInstance]configurePlayerRoute:[TKEduSessionHandle shareInstance].isPlayMedia isCancle:NO];
        }
        
        [self pluggInOrOutMicrophone:notify.userInfo];
        [self printAudioCurrentCategory];
        [self printAudioCurrentMode];
        [self printAudioCategoryOption];
        
    }
    
}
// 插拔耳机
-(void)pluggInOrOutMicrophone:(NSDictionary *)userInfo{
    NSDictionary *interuptionDict = userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            
            TKLog(@"---jin 耳机插入");
            [TKEduSessionHandle shareInstance].isHeadphones = YES;
            [TKEduSessionHandle shareInstance].iVolume = 0.5;
            // [[TKEduSessionHandle shareInstance]configurePlayerRoute:[TKEduSessionHandle shareInstance].isPlayMedia isCancle:NO];
            [[TKEduSessionHandle shareInstance]configurePlayerRoute: NO isCancle:NO];
            if ([TKEduSessionHandle shareInstance].isPlayMedia){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:
                 sPluggInMicrophoneNotification
                                                                    object:nil];
            }
            
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            
            [TKEduSessionHandle shareInstance].isHeadphones = NO;
            [TKEduSessionHandle shareInstance].iVolume = 1;
            [[TKEduSessionHandle shareInstance]configurePlayerRoute: NO isCancle:NO];
            //[[TKEduSessionHandle shareInstance]configurePlayerRoute:[TKEduSessionHandle shareInstance].isPlayMedia isCancle:NO];
            if ([TKEduSessionHandle shareInstance].isPlayMedia) {
                [[NSNotificationCenter defaultCenter] postNotificationName:sUnunpluggingHeadsetNotification
                                                                    object:nil];
            }
            
            TKLog(@"---jin 耳机拔出，停止播放操作");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            TKLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
    
}
//打印日志
- (void)printAudioCurrentCategory{
    
    NSString *audioCategory =  [AVAudioSession sharedInstance].category;
    if ( audioCategory == AVAudioSessionCategoryAmbient ){
        NSLog(@"---jin current category is : AVAudioSessionCategoryAmbient");
    } else if ( audioCategory == AVAudioSessionCategorySoloAmbient ){
        NSLog(@"---jin current category is : AVAudioSessionCategorySoloAmbient");
    } else if ( audioCategory == AVAudioSessionCategoryPlayback ){
        NSLog(@"---jin current category is : AVAudioSessionCategoryPlayback");
    }  else if ( audioCategory == AVAudioSessionCategoryRecord ){
        NSLog(@"---jin current category is : AVAudioSessionCategoryRecord");
    } else if ( audioCategory == AVAudioSessionCategoryPlayAndRecord ){
        NSLog(@"---jin current category is : AVAudioSessionCategoryPlayAndRecord");
    } else if ( audioCategory == AVAudioSessionCategoryAudioProcessing ){
        NSLog(@"---jin current category is : AVAudioSessionCategoryAudioProcessing");
    } else if ( audioCategory == AVAudioSessionCategoryMultiRoute ){
        NSLog(@"---jin current category is : AVAudioSessionCategoryMultiRoute");
    }  else {
        NSLog(@"---jin current category is : unknow");
    }
}

- (void)printAudioCurrentMode{
    
    
    NSString *audioMode =  [AVAudioSession sharedInstance].mode;
    if ( audioMode == AVAudioSessionModeDefault ){
        NSLog(@"---jin current mode is : AVAudioSessionModeDefault");
    } else if ( audioMode == AVAudioSessionModeVoiceChat ){
        NSLog(@"---jin current mode is : AVAudioSessionModeVoiceChat");
    } else if ( audioMode == AVAudioSessionModeGameChat ){
        NSLog(@"---jin current mode is : AVAudioSessionModeGameChat");
    }  else if ( audioMode == AVAudioSessionModeVideoRecording ){
        NSLog(@"---jin current mode is : AVAudioSessionModeVideoRecording");
    } else if ( audioMode == AVAudioSessionModeMeasurement ){
        NSLog(@"---jin current mode is : AVAudioSessionModeMeasurement");
    } else if ( audioMode == AVAudioSessionModeMoviePlayback ){
        NSLog(@"---jin current mode is : AVAudioSessionModeMoviePlayback");
    } else if ( audioMode == AVAudioSessionModeVideoChat ){
        NSLog(@"---jin current mode is : AVAudioSessionModeVideoChat");
    }else if ( audioMode == AVAudioSessionModeSpokenAudio ){
        NSLog(@"---jin current mode is : AVAudioSessionModeSpokenAudio");
    } else {
        NSLog(@"---jin current mode is : unknow");
    }
}
-(void)printAudioCategoryOption{
    NSString *tSString = @"AVAudioSessionCategoryOptionMixWithOthers";
    switch ([AVAudioSession sharedInstance].categoryOptions) {
        case AVAudioSessionCategoryOptionDuckOthers:
            tSString = @"AVAudioSessionCategoryOptionDuckOthers";
            break;
        case AVAudioSessionCategoryOptionAllowBluetooth:
            tSString = @"AVAudioSessionCategoryOptionAllowBluetooth";
            break;
        case AVAudioSessionCategoryOptionDefaultToSpeaker:
            tSString = @"AVAudioSessionCategoryOptionDefaultToSpeaker";
            break;
        case AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers:
            tSString = @"AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers";
            break;
        case AVAudioSessionCategoryOptionAllowBluetoothA2DP:
            tSString = @"AVAudioSessionCategoryOptionAllowBluetoothA2DP";
            break;
        case AVAudioSessionCategoryOptionAllowAirPlay:
            tSString = @"AVAudioSessionCategoryOptionAllowAirPlay";
            break;
        default:
            break;
    }
    
    TKLog(@"---jin current categoryOptions is :%@",tSString);
}

#pragma mark 开始
-(void)onClassReady{
    
    if(!_iRoomProperty.iHowMuchTimeServerFasterThenMe)
        return;
    
    if (![TKEduSessionHandle shareInstance].isClassBegin && _iUserType == UserType_Teacher) {
        _iRoomProperty.iCurrentTime = [[NSDate date]timeIntervalSince1970] + _iRoomProperty.iHowMuchTimeServerFasterThenMe;
        //1498569290.216449
        BOOL tEnabled = _iRoomProperty.iStartTime != 0 &&((int)((_iRoomProperty.iStartTime*1000 -_iRoomProperty.iCurrentTime*1000)/1000) < 60);
        [_iClassBeginAndRaiseHandButton setEnabled:tEnabled];
        _iClassBeginAndRaiseHandButton.backgroundColor = tEnabled ?RGBACOLOR_ClassBegin_RedDeep:RGBACOLOR_ClassEnd_Red ;
        
        
        if ((int)((_iRoomProperty.iCurrentTime*1000 -_iRoomProperty.iStartTime*1000)/1000)>=-60 &&((int)((_iRoomProperty.iCurrentTime*1000 -_iRoomProperty.iStartTime*1000)/1000)< 0 && !_iShowBefore)) {
            
            _iShowBefore = YES;
            [_iClassTimeView showPromte:PromptTypeStartReady1Minute aPassEndTime: ((_iRoomProperty.iCurrentTime*1000 -_iRoomProperty.iStartTime*1000)/1000) aPromptTime:5];
            
        }else if(((int)(_iRoomProperty.iCurrentTime*1000 -_iRoomProperty.iStartTime*1000)/1000)/60>=1 && !_iShow &&(_iRoomProperty.iCurrentTime-_iRoomProperty.iStartTime)>0 ){
            
            [_iClassTimeView showPromte:PromptTypeStartPass1Minute aPassEndTime: (int)((_iRoomProperty.iCurrentTime*1000 -_iRoomProperty.iStartTime*1000)/1000) aPromptTime:5];
            _iShow = YES;
            
            
        }
        
    }
    
}

-(void)invalidateClassReadyTime{
    if (_iClassReadyTimetimer) {
        [_iClassReadyTimetimer invalidate];
        _iClassReadyTimetimer = nil;
        [_iClassTimeView hidePromptView];
    }
    
}

-(void)startClassReadyTimer{
    
    _iRoomProperty.iCurrentTime = [[NSDate date]timeIntervalSince1970];
    [_iClassReadyTimetimer setFireDate:[NSDate date]];
}


-(void)onClassTimer {
    
    if(!_iRoomProperty.iHowMuchTimeServerFasterThenMe)
        return;
    
    _iRoomProperty.iCurrentTime = [[NSDate date]timeIntervalSince1970] + _iRoomProperty.iHowMuchTimeServerFasterThenMe;
    
    //_iLocalTime = _iTKEduClassRoomProperty.iCurrentTime - _iTKEduClassRoomProperty.iStartTime;
    [_iClassTimeView setClassTime:_iLocalTime];
    [self invalidateClassReadyTime];
    if ([TKEduSessionHandle shareInstance].isClassBegin && _iUserType == UserType_Teacher) {
        
        int tDele = (int)(_iRoomProperty.iCurrentTime*1000 - _iRoomProperty.iEndTime*1000)/1000;
        //距离下课3分钟
        BOOL tEnabled;
        if ([_iSessionHandle.roomMgr.companyId isEqualToString:YLB_COMPANYID]) {
            tEnabled = _iRoomProperty.iEndTime != 0 && tDele+60 >= 0;
        } else {
            tEnabled = YES;    // 下课总是可以点击的
        }
        
        [_iClassBeginAndRaiseHandButton setEnabled:tEnabled];
        _iClassBeginAndRaiseHandButton.backgroundColor = tEnabled?RGBACOLOR_ClassBegin_RedDeep:RGBACOLOR_ClassEnd_Red;
        [_iClassBeginAndRaiseHandButton setTitle:MTLocalized(@"Button.ClassIsOver") forState:UIControlStateNormal];
        PromptType tPromptType = PromptTypeEndWill1Minute;
        
        // 只有YLB显示下课提示
        if ([_iSessionHandle.roomMgr.companyId isEqualToString:YLB_COMPANYID]) {
            if ((tDele >= -60) && (tDele <= -59)) {
                
                tPromptType = PromptTypeEndWill1Minute;
                [_iClassTimeView showPromte:tPromptType aPassEndTime:1 aPromptTime:5];
            }else if (tDele>=180 && tDele<=181){
                
                tPromptType = PromptTypeEndPass3Minute;
                [_iClassTimeView showPromte:tPromptType aPassEndTime:3 aPromptTime:5];
            }else if(tDele >=290 &&tDele<=291){
                
                tPromptType = PromptTypeEndPass5Minute;
                [_iClassTimeView showPromte:tPromptType aPassEndTime:0 aPromptTime:10];
            }
            
            if((tDele >60) ){
                tPromptType = PromptTypeEndPass;
                [_iClassTimeView showPromte:tPromptType aPassEndTime:0 aPromptTime:0];
            }
            //设置黄色
            BOOL tEnd1Minute = !(tDele>=-60 && tDele <-55) && (tDele>-55)&& (tDele<0);
            if ((tEnd1Minute)) {
                
                tPromptType = PromptTypeEndWill1Minute;
                [_iClassTimeView showPromte:tPromptType aPassEndTime:0 aPromptTime:0];
            }
        }
        
        // 下课时间到，下课
        if (tDele>300) {
            
            [self configureHUD:@"" aIsShow:YES];
            __weak typeof(self)weakSelf =self;
            UIButton *tButton = _iClassBeginAndRaiseHandButton;
            [TKEduNetManager classBeginEnd:[TKEduSessionHandle shareInstance].iRoomProperties.iRoomId companyid:[TKEduSessionHandle shareInstance].iRoomProperties.iCompanyID aHost:[TKEduSessionHandle shareInstance].iRoomProperties.sWebIp aPort:[TKEduSessionHandle shareInstance].iRoomProperties.sWebPort aComplete:^int(id  _Nullable response) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [tButton setTitle:MTLocalized(@"Button.ClassBegin") forState:UIControlStateNormal];
                [[TKEduSessionHandle shareInstance] sessionHandleDelMsg:sClassBegin ID:sClassBegin To:sTellAll Data:@{} completion:nil];
                tButton.hidden = YES;
                
                [strongSelf configureHUD:@"" aIsShow:NO];
                return 0;
            } aNetError:^int(id  _Nullable response) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf configureHUD:@"" aIsShow:NO];
                return 0;
            }];
            
        }
    }
    _iLocalTime ++;
    
}
-(void)invalidateClassBeginTime{
    
    if (_iClassTimetimer) {
        [_iClassTimetimer invalidate];
        _iLocalTime = 0;
        _iClassTimetimer = nil;
    }
    
}

-(void)startClassBeginTimer{
    _iLocalTime = 0;
    [_iClassTimetimer setFireDate:[NSDate date]];
    [self invalidateClassReadyTime];
}
-(void)dealloc{
    NSLog(@"roomController----dealloc");
}
#pragma mark Wdeprecated

/*
 -(void)initReConnection{
 
 _iNoNetView  = ({
 __weak typeof(self) weekSelf = self;
 
 TKNONetWorkView *tTiew = [[TKNONetWorkView alloc]initWithFrame:self.view.frame withReconctionBlock:^(UIButton *aReconnectionBlockButton) {
 
 __strong typeof(weekSelf)strongSelf = weekSelf;
 TKLog(@"buttonClicked:----%@",strongSelf);
 aReconnectionBlockButton.enabled = NO;
 [strongSelf reconnectMeeting];
 
 
 }];
 
 tTiew;
 
 });
 _iNoNetView.hidden = YES;
 
 [_iScroll addSubview:_iNoNetView];
 
 __weak typeof(self)weekSelf = self;
 _iAFNetworkReachablitityManager = [TKAFNetworkReachabilityManager sharedManager];
 _iNetStatus = YES;
 // 2.设置网络状态改变后的处理
 [_iAFNetworkReachablitityManager setReachabilityStatusChangeBlock:^(TKAFNetworkReachabilityStatus status) {
 __strong typeof(self)strongSelf = weekSelf;
 
 // 当网络状态改变了, 就会调用这个block
 switch (status) {
 case TKAFNetworkReachabilityStatusUnknown: // 未知网络
 case TKAFNetworkReachabilityStatusNotReachable: // 没有网络(断网)
 {
 TKLog(@"没有网络(断网)");
 _iNetStatusTimer = [[TKTimer alloc]initWithTimeout:10 repeat:NO completion:^{
 _iNetStatus = NO;
 
 if (strongSelf.iTKEduClassRoomSessionHandle) {
 //[self reconnectMeeting];
 }else{
 TKLog(@"没有网络-------------------没有调用");
 }
 
 
 } queue:dispatch_get_main_queue()];
 [strongSelf.iNetStatusTimer start];
 break;
 }
 
 case TKAFNetworkReachabilityStatusReachableViaWWAN: // 手机自带网络
 case TKAFNetworkReachabilityStatusReachableViaWiFi: // WIFI
 {
 
 if (strongSelf.iNetStatusTimer) {
 [strongSelf.iNetStatusTimer invalidate];
 }else{
 TKLog(@"有网络-------------------没有调用");
 }
 TKLog(@"手机自带网络或者Wifi");
 break;
 }
 
 }
 }];
 [_iAFNetworkReachablitityManager startMonitoring];
 }
 -(void)hideNoNetView{
 _iNoNetView.hidden = YES;
 _iNoNetView.aReconnectionButton.enabled = YES;
 }
 -(void)showNoNetView{
 [self.view bringSubviewToFront:_iNoNetView];
 [self.view bringSubviewToFront:_titleView];
 _iNoNetView.hidden = NO;
 _iNoNetView.aReconnectionButton.enabled = YES;
 }
 */

@end

