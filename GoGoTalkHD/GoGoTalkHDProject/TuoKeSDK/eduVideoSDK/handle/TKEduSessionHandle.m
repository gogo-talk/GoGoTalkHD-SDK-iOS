//
//  TKEduSessionHandle.m
//  EduClassPad
//
//  Created by ifeng on 2017/5/10.
//  Copyright © 2017年 beijing. All rights reserved.
//

#import "TKEduSessionHandle.h"
#import "TKMacro.h"
#import "TKDocmentDocModel.h"
#import "TKMediaDocModel.h"
#import "TKChatMessageModel.h"
#import "TKEduRoomProperty.h"
#import "TKEduBoardHandle.h"
#import "TKUtil.h"
#import "RoomUser.h"
#import "TKDocumentListView.h"
#import "TKProgressHUD.h"

@import AVFoundation;
@interface RoomManager(test)
- (void)setTestServer:(NSString*)ip Port:(NSString*)port;
@end
@interface TKEduSessionHandle ()<RoomManagerDelegate,RoomWhiteBoard>

@property (nonatomic,strong) NSMutableArray *iMessageList;
@property (nonatomic,strong) NSMutableArray *iUserList;
@property (nonatomic,strong) NSMutableArray *iUserStdAndTchrList;
@property (nonatomic,strong) NSMutableDictionary *iSpecialUserDic;

@property (nonatomic,strong) NSMutableSet   *iUserPlayAudioArray;
@property (nonatomic,strong) NSMutableDictionary *iPendingButtonDic;

@property (nonatomic,strong) NSMutableDictionary *iUnPublisDic;
@property (strong, nonatomic)  UISlider *iAudioslider2;
@property (strong,nonatomic)TKProgressHUD *HUD;

@property (nonatomic,assign) BOOL getCameraFail;
@property (nonatomic,assign) BOOL getMicrophoneFail;

@end

@implementation TKEduSessionHandle

+(instancetype )shareInstance{
    
    static TKEduSessionHandle *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      singleton = [[TKEduSessionHandle alloc] init];
                  });
    
    return singleton;
}

-(void)initPlaybackRoomManager:(id<RoomWhiteBoard>)aRoomWhiteBoardDelegate {
    _roomMgr = [[RoomManager alloc] initPlaybackWithDelegate:self AndWB:aRoomWhiteBoardDelegate];
}

-(void)initClassRoomManager{
    _roomMgr = [[RoomManager alloc] initWithDelegate:self];
}
-(void)initClassRoomManager:(id<RoomWhiteBoard>)aRoomWhiteBoardDelegate{
    _roomMgr = [[RoomManager alloc] initWithDelegate:self AndWB:aRoomWhiteBoardDelegate];
}

- (void)configureSession:(NSDictionary*)paramDic
           aRoomDelegate:(id<TKEduRoomDelegate>) aRoomDelegate
        aSessionDelegate:(id<TKEduSessionDelegate>) aSessionDelegate
          aBoardDelegate:(id<TKEduBoardDelegate>)aBoardDelegate
         aRoomProperties:(TKEduRoomProperty*)aRoomProperties
{

#if TARGET_OS_IPHONE
    _iRoomDelegate     = aRoomDelegate;
    _iSessionDelegate  = aSessionDelegate;
    _iBoardDelegate    = aBoardDelegate;
    _iParamDic         = paramDic;
    aBoardDelegate ?[self initClassRoomManager:self] : [self initClassRoomManager];

#endif
    _iBoardHandle                = [[TKEduBoardHandle alloc]init];
    _iMessageList                = [[NSMutableArray alloc] init];
    _iUserList                   = [[NSMutableArray alloc] init];
    _iUserStdAndTchrList         = [[NSMutableArray alloc] init];
    _iSpecialUserDic             = [[NSMutableDictionary alloc]initWithCapacity:10];
    _iUserPlayAudioArray         = [[NSMutableSet alloc] init];
    _iRoomProperties             = aRoomProperties;
    _iPendingButtonDic = [[NSMutableDictionary alloc]initWithCapacity:10];
    _iPublishDic = [[NSMutableDictionary alloc]initWithCapacity:10];
    _iUnPublisDic = [[NSMutableDictionary alloc]initWithCapacity:10];
    _iMediaMutableDic = [[NSMutableDictionary alloc]initWithCapacity:10];
    _iDocmentMutableDic = [[NSMutableDictionary alloc]initWithCapacity:10];
    _iDocmentMutableArray =[[NSMutableArray alloc] init];
    _iMediaMutableArray = [[NSMutableArray alloc]init];
    
    _isClassBegin = NO;
    _iIsClassEnd = YES;
    _getCameraFail = NO;
    _getMicrophoneFail = NO;
    _isPlayMedia = NO;
    _iIsPlaying = NO;
    _isLocal = NO;
    _isChangeMedia = NO;
    _iHasPublishStd = NO;
    _iStdOutBottom = NO;
    _iIsFullState = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
  
}

- (void)configurePlaybackSession:(NSDictionary*)paramDic
           aRoomDelegate:(id<TKEduRoomDelegate>) aRoomDelegate
        aSessionDelegate:(id<TKEduSessionDelegate>) aSessionDelegate
          aBoardDelegate:(id<TKEduBoardDelegate>)aBoardDelegate
         aRoomProperties:(TKEduRoomProperty*)aRoomProperties
{
    
#if TARGET_OS_IPHONE
    _iRoomDelegate     = aRoomDelegate;
    _iSessionDelegate  = aSessionDelegate;
    _iBoardDelegate    = aBoardDelegate;
    _iParamDic         = paramDic;
    
    //aBoardDelegate ?[self initClassRoomManager:self] : [self initClassRoomManager];
    [self initPlaybackRoomManager:self];
#endif
    _iBoardHandle                = [[TKEduBoardHandle alloc]init];
    _iMessageList                = [[NSMutableArray alloc] init];
    _iUserList                   = [[NSMutableArray alloc] init];
    _iUserStdAndTchrList         = [[NSMutableArray alloc] init];
    _iSpecialUserDic             = [[NSMutableDictionary alloc]initWithCapacity:10];
    _iUserPlayAudioArray         = [[NSMutableSet alloc] init];
    _iRoomProperties             = aRoomProperties;
    _iPendingButtonDic = [[NSMutableDictionary alloc]initWithCapacity:10];
    _iPublishDic = [[NSMutableDictionary alloc]initWithCapacity:10];
    _iUnPublisDic = [[NSMutableDictionary alloc]initWithCapacity:10];
    _iMediaMutableDic = [[NSMutableDictionary alloc]initWithCapacity:10];
    _iDocmentMutableDic = [[NSMutableDictionary alloc]initWithCapacity:10];
    _iDocmentMutableArray =[[NSMutableArray alloc] init];
    _iMediaMutableArray = [[NSMutableArray alloc]init];
    
    _isPlayMedia = NO;
    _iIsPlaying = NO;
    _isLocal = NO;
    _isChangeMedia = NO;
    _iHasPublishStd = NO;
    _iStdOutBottom = NO;
    _iIsFullState = NO;
   
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    
}




-(void)joinEduClassRoomWithParam:(NSDictionary *)aParamDic aProperties:(NSDictionary *)aProperties{
    if (_roomMgr) {
        
#ifdef Debug
        //8889 8891
        [_roomMgr setTestServer:@"192.168.1.25" Port:@"8889"];
#endif
       
        NSString *tHost = [_iParamDic objectForKey:@"host"]?[_iParamDic objectForKey:@"host"]:sHost;
        NSString *tPort = [_iParamDic objectForKey:@"port"]?[_iParamDic objectForKey:@"port"]:sPort;
        NSString *tNickName = [_iParamDic objectForKey:@"nickname"]?[_iParamDic objectForKey:@"nickname"]:@"test";
        bool isConform = [TKUtil  deviceisConform];
        isConform      = true;
        // 先检测麦克风
        AVAuthorizationStatus authAudioStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if (authAudioStatus == AVAuthorizationStatusRestricted|| authAudioStatus == AVAuthorizationStatusDenied) {
            // 获取麦克风失败
            //[self callMicrophoneError];
            self.getMicrophoneFail = YES;
        } else if (authAudioStatus == AVAuthorizationStatusNotDetermined || authAudioStatus == AVAuthorizationStatusAuthorized) {
            // 麦克风
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if (granted) {
                    // 获取摄像头成功
                } else {
                    //[self callMicrophoneError];
                }
            }];
        }
        
        // 摄像头
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted|| authStatus == AVAuthorizationStatusDenied) {
            // 获取摄像头失败
            //[self callCameroError];
            self.getCameraFail = YES;
            
            // 禁用摄像头也能进入房间
            if (self.isPlayback) {
                [_roomMgr joinPlaybackRoomWithHost:tHost Port:(int)[tPort integerValue] NickName:tNickName Params:aParamDic Properties:aProperties lowConsume:!isConform];
            } else {
                [_roomMgr joinRoomWithHost:tHost Port:(int)[tPort integerValue] NickName:tNickName Params:aParamDic Properties:aProperties lowConsume:!isConform];
            }
        } else if(authStatus == AVAuthorizationStatusNotDetermined || authStatus == AVAuthorizationStatusAuthorized) {
            // 摄像头
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    // 获取摄像头成功
                    
                    // 进入房间
                    if (self.isPlayback) {
                        [_roomMgr joinPlaybackRoomWithHost:tHost Port:(int)[tPort integerValue] NickName:tNickName Params:aParamDic Properties:aProperties lowConsume:!isConform];
                    } else {
                        [_roomMgr joinRoomWithHost:tHost Port:(int)[tPort integerValue] NickName:tNickName Params:aParamDic Properties:aProperties lowConsume:!isConform];
                    }
                } else {
                    // 获取摄像头失败
                    
                    // 进入房间
                    if (self.isPlayback) {
                        [_roomMgr joinPlaybackRoomWithHost:tHost Port:(int)[tPort integerValue] NickName:tNickName Params:aParamDic Properties:aProperties lowConsume:!isConform];
                    } else {
                        [_roomMgr joinRoomWithHost:tHost Port:(int)[tPort integerValue] NickName:tNickName Params:aParamDic Properties:aProperties lowConsume:!isConform];
                    }
                }
            }];
        } else {
            // 获取摄像头成功
        }
        
        // 设备缺失提示
        [self checkDevice];
    }
}



#pragma mark session方法
- (void)sessionHandleLeaveRoom:(void (^)(NSError *error))block {
   
    return [_roomMgr leaveRoom:block];
}
-(void)sessionHandleLeaveRoom:(BOOL)force Completion:(void (^)(NSError *))block{
    return[_roomMgr leaveRoom:force Completion:block];
}

//看视频
- (void)sessionHandlePlayVideo:(NSString*)peerID completion:(void (^)(NSError *error, NSObject *view))block{
     return [_roomMgr playVideo:peerID completion:block];
}
//不看
- (void)sessionHandleUnPlayVideo:(NSString*)peerID completion:(void (^)(NSError *error))block{
    return [_roomMgr unPlayVideo:peerID completion:block];
}
//状态变化
- (void)sessionHandleChangeUserProperty:(NSString*)peerID TellWhom:(NSString*)tellWhom Key:(NSString*)key Value:(NSObject*)value completion:(void (^)(NSError *error))block{
    return [_roomMgr changeUserProperty:peerID TellWhom:tellWhom Key:key Value:value completion:block];
    
}
//
- (void)sessionHandleChangeUserPublish:(NSString*)peerID Publish:(int)publish completion:(void (^)(NSError *error))block{
    return [_roomMgr changeUserPublish:peerID Publish:publish completion:block];
}

- (void)sessionHandleSendMessage:(NSString*)message completion:(void (^)(NSError *error))block{
     return [_roomMgr sendMessage:message completion:block];
}

//- (void)sessionHandlePubMsg:(NSString*)msgName ID:(NSString*)msgID To:(NSString*)toID Data:(NSObject*)data Save:(BOOL)save completion:(void (^)(NSError *error))block{
//   return [_roomMgr pubMsg:msgName ID:msgID To:toID Data:data Save:save completion:block];
//}

- (void)sessionHandlePubMsg:(NSString *)msgName ID:(NSString *)msgID To:(NSString *)toID Data:(NSObject *)data Save:(BOOL)save AssociatedMsgID:(NSString *)associatedMsgID AssociatedUserID:(NSString *)associatedUserID completion:(void (^)(NSError *))block {
    return [_roomMgr pubMsg:msgName ID:msgID To:toID Data:data Save:save AssociatedMsgID:associatedMsgID AssociatedUserID:associatedUserID completion:block];
}

- (void)sessionHandleDelMsg:(NSString*)msgName ID:(NSString*)msgID To:(NSString*)toID Data:(NSObject*)data completion:(void (^)(NSError *error))block{
    return [_roomMgr delMsg:msgName ID:msgID To:toID Data:data completion:block];
}

- (void)sessionHandleEvictUser:(NSString*)peerID completion:(void (^)(NSError *error))block{
    return [_roomMgr evictUser:peerID completion:block];
}


//WebRTC & Media

- (void)sessionHandleSelectCameraPosition:(BOOL)isFront{
     return [_roomMgr selectCameraPosition:isFront];
}

- (BOOL)sessionHandleIsVideoEnabled{
    return [_roomMgr isVideoEnabled];
}

- (void)sessionHandleEnableVideo:(BOOL)enable{
     return [_roomMgr enableVideo:enable];
}

- (BOOL)sessionHandleIsAudioEnabled{
   return [_roomMgr isAudioEnabled];
}
- (void)sessionHandleEnableAllAudio:(BOOL)enable{
    
    [self sessionHandleEnableOtherAudio:enable];
    [self sessionHandleEnableAudio:enable];
}
- (void)sessionHandleEnableAudio:(BOOL)enable{
     return [_roomMgr enableAudio:enable];
}
- (void)sessionHandleEnableOtherAudio:(BOOL)enable{
     [_roomMgr enableOtherAudio:enable];
}

-(void)sessionHandleUseLoudSpeaker:(BOOL)use{
    return [self sessionUseLoudSpeaker:use];
}
-(void)sessionUseLoudSpeaker:(BOOL)use{
    AVAudioSession* session = [AVAudioSession sharedInstance];
    NSError* error;
    if (_isHeadphones) {
        [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth  error:nil];
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
        return;
    }
    
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
    if (!use) {
        
        [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth error:&error];
        [session setMode:AVAudioSessionModeVoiceChat error:nil];
        
    }else{
        
        [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth  error:&error];
        [session setMode:AVAudioSessionModeDefault  error:nil];
        
    }
    [session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    //[_session sessionUseLoudSpeaker:use];
}

#pragma mark room manager delegate
//1自己进入课堂
- (void)roomManagerRoomJoined:(NSError *)error {
    
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerRoomJoined:)]) {
        [(id<TKEduSessionDelegate>)_iSessionDelegate sessionManagerRoomJoined:error];
        
    }
    if (_iRoomDelegate && [_iRoomDelegate respondsToSelector:@selector(joinRoomComplete)]) {
        [(id<TKEduRoomDelegate>)_iRoomDelegate  joinRoomComplete];
        
    }
    TKLog(@"jin roomManagerRoomJoined %@", error);
    
}
//2自己离开课堂
- (void)roomManagerRoomLeft {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerRoomLeft)]) {
        [(id<TKEduSessionDelegate>)_iSessionDelegate sessionManagerRoomLeft];
        
    }
    if (_iRoomDelegate && [_iRoomDelegate respondsToSelector:@selector(leftRoomComplete)]) {
        [(id<TKEduRoomDelegate>)_iRoomDelegate  leftRoomComplete];
        
    }
     TKLog(@"jin roomManagerRoomLeft");
}
// 被踢
- (void)roomManagerSelfEvicted{
    //classbegin
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerSelfEvicted)]) {
       
        [(id<TKEduSessionDelegate>)_iSessionDelegate sessionManagerSelfEvicted];
        
    }
    if (_iRoomDelegate && [_iRoomDelegate respondsToSelector:@selector(onKitout:)]) {
        
        [(id<TKEduRoomDelegate>)_iRoomDelegate onKitout:EKickOutReason_Repeat];
        
    }
     TKLog(@"jin roomManagerSelfEvicted");
    
}
//3观看视频
- (void)roomManagerUserPublished:(RoomUser *)user {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerUserPublished:)]) {
        [(id<TKEduSessionDelegate>)_iSessionDelegate sessionManagerUserPublished:user];
        
    }
     TKLog(@"jin roomManagerUserPublished");
}
//4取消视频
- (void)roomManagerUserUnpublished:(RoomUser *)user {
    
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerUserUnpublished:)]) {
        [(id<TKEduSessionDelegate>)_iSessionDelegate sessionManagerUserUnpublished:user];
        
    }
     TKLog(@"jin roomManagerUserUnpublished");
}

//5用户进入
- (void)roomManagerUserJoined:(RoomUser *)user InList:(BOOL)inList {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerUserJoined:InList:)]) {
        [(id<TKEduSessionDelegate>)_iSessionDelegate sessionManagerUserJoined:user InList:inList];
        
    }
     TKLog(@"jin roomManagerUserJoined");
}

//6用户离开
- (void)roomManagerUserLeft:(RoomUser *)user {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerUserLeft:)]) {
        
        [(id<TKEduSessionDelegate>)_iSessionDelegate sessionManagerUserLeft:user];
        
    }
     TKLog(@"jin roomManagerUserLeft");
}
//7用户信息变化
- (void)roomManagerUserChanged:(RoomUser *)user Properties:(NSDictionary*)properties{
    
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerUserChanged:Properties:)]) {
        [(id<TKEduSessionDelegate>)_iSessionDelegate sessionManagerUserChanged:user Properties:properties];
        
    }
      TKLog(@"jin roomManagerUserChanged");
}

//8聊天信息
- (void)roomManagerMessageReceived:(NSString *)message ofUser:(RoomUser *)user {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerMessageReceived:ofUser:)]) {
        [(id<TKEduSessionDelegate>)_iSessionDelegate sessionManagerMessageReceived:message ofUser:user];
    }
}

// 回放聊天信息带有时间戳
- (void)roomManagerPlaybackMessageReceived:(NSString *)message ofUser:(RoomUser *)user ts:(NSTimeInterval)ts {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerPlaybackMessageReceived:ofUser:ts:)]) {
        [(id<TKEduSessionDelegate>)_iSessionDelegate sessionManagerPlaybackMessageReceived:message ofUser:user ts:ts];
    }
}


//9进入会议失败
- (void)roomManagerDidFailWithError:(NSError *)error {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerDidFailWithError:)]) {
        [(id<TKEduSessionDelegate>)_iSessionDelegate sessionManagerDidFailWithError:error];
        
    }
    if (_iRoomDelegate && [_iRoomDelegate respondsToSelector:@selector(onEnterRoomFailed:Description:)]) {
        
        [(id<TKEduRoomDelegate>)_iRoomDelegate onEnterRoomFailed:(int)error.code Description:error.description];
        
        
    }
    TKLog(@"jin roomManagerDidFailWithError %@", error);
}
//10白板等相关信令
- (void)roomManagerOnRemoteMsg:(BOOL)add ID:(NSString*)msgID Name:(NSString*)msgName TS:(unsigned long)ts Data:(NSObject*)data InList:(BOOL)inlist{
    //classbegin
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerOnRemoteMsg:ID:Name:TS:Data:InList:)]) {
        [(id<TKEduSessionDelegate>) _iSessionDelegate sessionManagerOnRemoteMsg:add ID:msgID Name:msgName TS:ts Data:data InList:inlist];
        
    }
    //会议开始或者结束
    if ([msgName isEqualToString:sClassBegin]) {
        if (add) {
            
            if (_iRoomDelegate && [_iRoomDelegate respondsToSelector:@selector(onClassBegin)]) {
                
                [(id<TKEduRoomDelegate>)_iRoomDelegate onClassBegin];
                
            }
        }else{
            
            if (_iRoomDelegate && [_iRoomDelegate respondsToSelector:@selector(onClassDismiss)]) {
                [(id<TKEduRoomDelegate>)_iRoomDelegate onClassDismiss];
                
            }
        }
        
        
    }
     TKLog(@"jin roomManagerOnRemoteMsg");
    
    
}

// 首次发布或订阅失败3次通知
- (void)roomManagerReportNetworkProblem {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(networkTrouble)]) {
        [(id<TKEduSessionDelegate>) _iSessionDelegate networkTrouble];
    }
}

// 连接服务器成功
- (void)roomManagerConnected:(void(^)())completion {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerGetGiftNumber:)]) {
        [(id<TKEduSessionDelegate>)_iSessionDelegate sessionManagerGetGiftNumber:completion];
    }
}


#pragma mark media
-(void)roomManagerMediaPublish:(MediaStream*)mediaStream roomUser:(RoomUser *)user{
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerMediaPublish:roomUser:)]) {
        [(id<TKEduSessionDelegate>) _iSessionDelegate sessionManagerMediaPublish:mediaStream roomUser:user];
        
    }
}
-(void)roomManagerMediaUnPublish:(MediaStream*)mediaStream roomUser:(RoomUser *)user{
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerMediaUnPublish:roomUser:)]) {
        [(id<TKEduSessionDelegate>) _iSessionDelegate sessionManagerMediaUnPublish:mediaStream roomUser:user];
    }
}

-(void)roomManagerUpdateMediaStream:(MediaStream*)mediaStream pos:(NSTimeInterval)pos isPlay:(BOOL)isPlay{
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerMediaUnPublish:roomUser:)]) {
        [(id<TKEduSessionDelegate>) _iSessionDelegate sessionManagerUpdateMediaStream:mediaStream pos:pos isPlay:isPlay];
    }
}

#pragma mark screen
- (void)roomManagerScreenPublished:(RoomUser *)user {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerScreenPublish:)]) {
        [(id<TKEduSessionDelegate>) _iSessionDelegate sessionManagerScreenPublish:user];
    }
}

- (void)roomManagerScreenUnPublished:(RoomUser *)user {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerScreenUnPublish:)]) {
        [(id<TKEduSessionDelegate>) _iSessionDelegate sessionManagerScreenUnPublish:user];
    }
}

#pragma mark Playback

- (void)roomManagerPlaybackClearAll {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerPlaybackClearAll)]) {
        [(id<TKEduSessionDelegate>) _iSessionDelegate sessionManagerPlaybackClearAll];
    }
}

- (void)roomManagerReceivePlaybackDuration:(NSTimeInterval)duration {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerReceivePlaybackDuration:)]) {
        [(id<TKEduSessionDelegate>) _iSessionDelegate sessionManagerReceivePlaybackDuration:duration];
    }
}

- (void)roomManagerPlaybackUpdateTime:(NSTimeInterval)time {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerPlaybackUpdateTime:)]) {
        [(id<TKEduSessionDelegate>) _iSessionDelegate sessionManagerPlaybackUpdateTime:time];
    }
}

- (void)roomManagerPlaybackEnd {
    if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(sessionManagerPlaybackEnd)]) {
        [(id<TKEduSessionDelegate>) _iSessionDelegate sessionManagerPlaybackEnd];
    }
}

#pragma mark roomWhiteBoard Delegate

- (void)onUserPublished:(RoomUser *)user {
    NSMutableDictionary *onStageUserDic = [[NSMutableDictionary alloc] init];
    for (RoomUser *user in [self.iPublishDic allValues]) {
        if (user.role == UserType_Student) {
            [onStageUserDic setObject:user.nickName forKey:user.peerID];
        }
    }
    if (user && user.role == UserType_Student) {
        [onStageUserDic setObject:user.nickName forKey:user.peerID];
        
        NSData *tJsonData = [NSJSONSerialization dataWithJSONObject:onStageUserDic options:NSJSONWritingPrettyPrinted error:nil];
        NSString *tJsonString = [[NSString alloc]initWithData:tJsonData encoding:NSUTF8StringEncoding];
        NSString *jsReceivePhoneByTriggerEvent = [NSString stringWithFormat:@"GLOBAL.phone.userSelector(%@)",tJsonString];
        [_iBoardHandle.iWebView evaluateJavaScript:jsReceivePhoneByTriggerEvent completionHandler:^(id _Nullable id, NSError * _Nullable error) {
            NSLog(@"----GLOBAL.phone.userSelector");
        }];
    }
}

- (void)onUserUnpublished:(RoomUser *)user {
    NSMutableDictionary *onStageUserDic = [[NSMutableDictionary alloc] init];
    for (RoomUser *user in [self.iPublishDic allValues]) {
        if (user.role == UserType_Student) {
            [onStageUserDic setObject:user.nickName forKey:user.peerID];
        }
    }
    if (user && user.role == UserType_Student) {
        [onStageUserDic removeObjectForKey:user.peerID];
        
        NSData *tJsonData = [NSJSONSerialization dataWithJSONObject:onStageUserDic options:NSJSONWritingPrettyPrinted error:nil];
        NSString *tJsonString = [[NSString alloc]initWithData:tJsonData encoding:NSUTF8StringEncoding];
        NSString *jsReceivePhoneByTriggerEvent = [NSString stringWithFormat:@"GLOBAL.phone.userSelector(%@)",tJsonString];
        [_iBoardHandle.iWebView evaluateJavaScript:jsReceivePhoneByTriggerEvent completionHandler:^(id _Nullable id, NSError * _Nullable error) {
            NSLog(@"----GLOBAL.phone.userSelector");
        }];
    }
}

- (void)onUserLeft:(RoomUser *)user {
    NSMutableDictionary *onStageUserDic = [[NSMutableDictionary alloc] init];
    for (RoomUser *user in [self.iPublishDic allValues]) {
        if (user.role == UserType_Student) {
            [onStageUserDic setObject:user.nickName forKey:user.peerID];
        }
    }
    
    if (user && [onStageUserDic objectForKey:user.peerID] && user.role == UserType_Student) {
        [onStageUserDic removeObjectForKey:user.peerID];
        
        NSData *tJsonData = [NSJSONSerialization dataWithJSONObject:onStageUserDic options:NSJSONWritingPrettyPrinted error:nil];
        NSString *tJsonString = [[NSString alloc]initWithData:tJsonData encoding:NSUTF8StringEncoding];
        NSString *jsReceivePhoneByTriggerEvent = [NSString stringWithFormat:@"GLOBAL.phone.userSelector(%@)",tJsonString];
        [_iBoardHandle.iWebView evaluateJavaScript:jsReceivePhoneByTriggerEvent completionHandler:^(id _Nullable id, NSError * _Nullable error) {
            NSLog(@"----GLOBAL.phone.userSelector");
        }];
    }
}

- (void)onFileList:(NSArray*)fileList{
  
    TKLog(@"jin onFileList");
 
    
    //添加一个白板
    NSDictionary *tDic = [self whiteBoardDic];
    NSMutableArray *tMutableFileList = [NSMutableArray arrayWithArray:fileList];
    [tMutableFileList insertObject:tDic atIndex:0];
    
    if (_iBoardDelegate && [_iBoardDelegate respondsToSelector:@selector(boardOnFileList:)]) {
        [_iBoardDelegate boardOnFileList:tMutableFileList];
        
    }
    int i = 0;
    
    for (NSDictionary *tFileDic in tMutableFileList) {
        //如果是媒体文档，则跳过
        if ([TKUtil getIsMedia:[tFileDic objectForKey:@"filetype"]]) {
            TKMediaDocModel *tMediaDocModel = [[TKMediaDocModel alloc]init];
            [tMediaDocModel setValuesForKeysWithDictionary:tFileDic];
            tMediaDocModel.isPlay = @(NO);
            [self addOrReplaceMediaArray:tMediaDocModel];
            
        }else{
            
            TKDocmentDocModel *tDocmentDocModel = [[TKDocmentDocModel alloc]init];
            [tDocmentDocModel setValuesForKeysWithDictionary:tFileDic];
            [tDocmentDocModel dynamicpptUpdate];
            [self addOrReplaceDocmentArray:tDocmentDocModel];
            if ([tDocmentDocModel.dynamicppt integerValue]==1) {
                continue;
            }
            if (i == 1 || i==0 || [[NSString stringWithFormat:@"%@",tDocmentDocModel.type] isEqualToString:@"1"]) {
                _iDefaultDocment = tDocmentDocModel;
                _iCurrentDocmentModel= _iDefaultDocment;
            }
            
            i++;
        }
        
    }
    
    // 文档排序
    [_iDocmentMutableArray sortUsingComparator:^NSComparisonResult(TKDocmentDocModel *  _Nonnull obj1, TKDocmentDocModel *  _Nonnull obj2) {
        
        if (obj1.fileid.intValue > obj2.fileid.intValue) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        
        if (obj1.fileid.intValue < obj2.fileid.intValue) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        
        return (NSComparisonResult)NSOrderedSame;
    }];
    
    // 媒体排序
    [_iMediaMutableArray sortUsingComparator:^NSComparisonResult(TKMediaDocModel *  _Nonnull obj1, TKMediaDocModel *  _Nonnull obj2) {
        
        if (obj1.fileid.intValue > obj2.fileid.intValue) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        
        if (obj1.fileid.intValue < obj2.fileid.intValue) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        
        return (NSComparisonResult)NSOrderedSame;
    }];
    
    // 测试
    for (TKDocmentDocModel *model in _iDocmentMutableArray) {
        TKLog(@"文档 %ld", (long)model.fileid.integerValue);
    }
    
    for (TKMediaDocModel *model in _iMediaMutableArray) {
        TKLog(@"媒体 %ld", (long)model.fileid.integerValue);
    }
}

- (void)onRemoteMsgList:(NSArray*)list{
    TKLog(@"jin onRemoteMsgList");
    NSMutableDictionary *tParamDic = [[NSMutableDictionary alloc]initWithCapacity:10];
    BOOL tIsHavePageList = NO;
    BOOL tIsCanPage      = NO;
    for (NSDictionary *tParamDictemp in list) {
        NSString *tID = [tParamDictemp objectForKey:@"id"];
        [tParamDic setObject:tParamDictemp forKey:tID];
        
        if ([[tParamDictemp objectForKey:@"name"] isEqualToString:sShowPage]) {
            tIsHavePageList = YES;
            NSString *dataJson = [tParamDictemp objectForKey:@"data"];
            NSDictionary *tDataDic = @{};
            
            //TKLog(@"-----%@", [NSString stringWithFormat:@"msgName:%@,msgID:%@",msgName,msgID]);
            if ([dataJson isKindOfClass:[NSString class]]) {
                NSString *tDataString = [NSString stringWithFormat:@"%@",dataJson];
                NSData *tJsData = [tDataString dataUsingEncoding:NSUTF8StringEncoding];
                tDataDic = [NSJSONSerialization JSONObjectWithData:tJsData options:NSJSONReadingMutableContainers error:nil];
            }
            if ([dataJson isKindOfClass:[NSDictionary class]]) {
                tDataDic = (NSDictionary *)dataJson;
            }
            
            NSDictionary *filedata = [tDataDic objectForKey:@"filedata"];
            NSString *key = [filedata objectForKey:@"fileid"];
            _iPreDocmentModel = _iCurrentDocmentModel;
            
            _iCurrentDocmentModel = [_iDocmentMutableDic objectForKey:key];
            
            
        }
        if ([[tParamDictemp objectForKey:@"name"] isEqualToString:sClassBegin]) {
            tIsCanPage = YES;
        }
        
    }
    NSData *tJsonData = [NSJSONSerialization dataWithJSONObject:tParamDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *tJsonString = [[NSString alloc]initWithData:tJsonData encoding:NSUTF8StringEncoding];
    NSString *jsReceivePhoneByTriggerEvent = [NSString stringWithFormat:@"GLOBAL.phone.receivePhoneByTriggerEvent('message-list-received', %@)",tJsonString];
    [_iBoardHandle.iWebView evaluateJavaScript:jsReceivePhoneByTriggerEvent completionHandler:^(id _Nullable id, NSError * _Nullable error) {
        NSLog(@"----GLOBAL.phone.receivePhoneByTriggerEvent");
    }];
    if (!tIsHavePageList) {
        [self docmentDefault:_iDefaultDocment];
        
    }else{
        
        NSData *tJsonData = [NSJSONSerialization dataWithJSONObject:tParamDic options:NSJSONWritingPrettyPrinted error:nil];
        NSString *tJsonString = [[NSString alloc]initWithData:tJsonData encoding:NSUTF8StringEncoding];
        NSString *jsReceivePhoneByTriggerEvent = [NSString stringWithFormat:@"GLOBAL.phone.receivePhoneByTriggerEvent('message-list-received', %@)",tJsonString];
        [_iBoardHandle.iWebView evaluateJavaScript:jsReceivePhoneByTriggerEvent completionHandler:^(id _Nullable id, NSError * _Nullable error) {
            NSLog(@"----GLOBAL.phone.receivePhoneByTriggerEvent");
        }];
    }
    
    
    if (_iBoardDelegate && [_iBoardDelegate respondsToSelector:@selector(boardOnRemoteMsgList:)]) {
        [_iBoardDelegate boardOnRemoteMsgList:list];
        
    }
    
    
}


//YES ，代表白板处理 不传给会议；  NO ，代表白板不处理，传给会议
- (BOOL)onRemoteMsg:(BOOL)add ID:(NSString*)msgID Name:(NSString*)msgName TS:(long)ts Data:(NSObject*)data InList:(BOOL)inlist fromID:(NSString *)fromId{
    TKLog(@"jin onRemoteMsg %@",msgName);
    BOOL tIsWhiteBoardDealWith = false;
    NSDictionary *tDataDic = @{};
   
    //TKLog(@"-----%@", [NSString stringWithFormat:@"msgName:%@,msgID:%@",msgName,msgID]);
    if ([data isKindOfClass:[NSString class]]) {
        NSString *tDataString = [NSString stringWithFormat:@"%@",data];
        NSData *tJsData = [tDataString dataUsingEncoding:NSUTF8StringEncoding];
        tDataDic = [NSJSONSerialization JSONObjectWithData:tJsData options:NSJSONReadingMutableContainers error:nil];
    }
    if ([data isKindOfClass:[NSDictionary class]]) {
        tDataDic = (NSDictionary *)data;
    }

    if ([msgName isEqualToString:sDocumentChange])
    {
        
        
        BOOL tIsDelete = [[tDataDic objectForKey:@"isDel"]boolValue];
        
        if (tIsDelete && [tDataDic objectForKey:@"isDel"]) {
            bool tIsMedia = [[tDataDic objectForKey:@"isMedia"]boolValue];
            if (tIsMedia) {

                TKMediaDocModel *tMediaDocModel = [self resolveMediaModelFromDic:tDataDic];
                UserType role = self.localUser.role;
                BOOL isCurrntDM = [self isEqualFileId:tMediaDocModel aSecondModel:_iCurrentMediaDocModel];
            
                //老师-当前文档
                if (role == UserType_Teacher && isCurrntDM && self.isPlayMedia) {
                    [self sessionHandleUnpublishMedia:nil];
                }
                [self delMediaArray:tMediaDocModel];
                
            } else {
                

                TKDocmentDocModel *tDocmentDocModel = [self resolveDocumentModelFromDic:tDataDic];
                UserType role = self.localUser.role;
               
                BOOL isCurrntDM = [self isEqualFileId:tDocmentDocModel aSecondModel:_iCurrentDocmentModel];
                
                //学生-当前文档-未上课，删除时显示白板
                if (role == UserType_Student && isCurrntDM &&!_isClassBegin) {
                    [self docmentDefault:self.docmentArray.firstObject];
                   
                }
                //老师-当前文档
                if (role == UserType_Teacher && isCurrntDM) {
                    if (!_isClassBegin) {
                        [self docmentDefault:[self getNextDocment:tDocmentDocModel]];
                        if (self.isPlayMedia) {
                            // 如果PPT里面有视频，要取消
                            [self sessionHandleUnpublishMedia:nil];
                        }
                    }
                   /*
                    if (_isClassBegin) {
                        [self publishtDocMentDocModel:[self getNextDocment:tDocmentDocModel] To:sTellAllExpectSender aTellLocal:YES];
                    
                        // 老师的当前文档被删除，在上课时也只是显示下一个文档，不发showpage
                        [self docmentDefault:[self getNextDocment:tDocmentDocModel]];
                        if (self.isPlayMedia) {
                            // 如果PPT里面有视频，要取消
                            [self sessionHandleUnpublishMedia:nil];
                        }
                    }else{
                        
                        [self docmentDefault:[self getNextDocment:tDocmentDocModel]];
                        if (self.isPlayMedia) {
                            // 如果PPT里面有视频，要取消
                            [self sessionHandleUnpublishMedia:nil];
                        }
                    }*/
                    
                }
                //先设置后删除
                [self delDocmentArray:tDocmentDocModel];
            }
            
            
        }else{
            bool tIsMedia = [[tDataDic objectForKey:@"isMedia"]boolValue];
            if (tIsMedia) {

                TKMediaDocModel *tMediaDocModel = [self resolveMediaModelFromDic:tDataDic];
                if (!tMediaDocModel.swfpath) {
                    tMediaDocModel.swfpath =tMediaDocModel.fileurl;
                }
                if (!tMediaDocModel.filetype) {
                    tMediaDocModel.filetype = [tMediaDocModel.filename pathExtension];
                }
                [self addOrReplaceMediaArray:tMediaDocModel];
                
                
            }else{
                
                TKDocmentDocModel *tDocmentDocModel = [self resolveDocumentModelFromDic:tDataDic];
                if (!tDocmentDocModel.swfpath) {
                    tDocmentDocModel.swfpath =  tDocmentDocModel.fileurl;
                }
                if (!tDocmentDocModel.filetype) {
                    tDocmentDocModel.filetype = [tDocmentDocModel.filename pathExtension];
                }
                [self addOrReplaceDocmentArray:tDocmentDocModel];
            }
            
        }
        [[NSNotificationCenter defaultCenter]postNotificationName:sDocListViewNotification object:nil];
    }
    
    
    if([msgName isEqualToString:sWBPageCount]|| [msgName isEqualToString:sShowPage] ||[msgName isEqualToString:sSharpsChange] )
    {
        
        if ([msgID isEqualToString:sDocumentFilePage_ShowPage]) {
            

            TKDocmentDocModel *tDocmentDocModel = [self resolveDocumentModelFromDic:tDataDic];
            if (!tDocmentDocModel.swfpath) {
                tDocmentDocModel.swfpath =  tDocmentDocModel.fileurl;
            }
            if (!tDocmentDocModel.filetype) {
                tDocmentDocModel.filetype = [tDocmentDocModel.filename pathExtension];
            }
            [self addOrReplaceDocmentArray:tDocmentDocModel];
            _iCurrentDocmentModel = tDocmentDocModel;
             [[NSNotificationCenter defaultCenter]postNotificationName:sDocListViewNotification object:nil];
        }
        if ([msgID isEqualToString:sWBPageCount]) {

            NSNumber*  tTotalPage = [tDataDic objectForKey:@"totalPage"]?[tDataDic objectForKey:@"totalPage"]:@(1);
            NSNumber*  fileid = [tDataDic objectForKey:@"fileid"]?[tDataDic objectForKey:@"fileid"]:@(0);
            TKDocmentDocModel *tDocmentDocModel = [self.iDocmentMutableDic objectForKey:[NSString stringWithFormat:@"%@",fileid]];
            tDocmentDocModel.pagenum  = tTotalPage?tTotalPage:tDocmentDocModel.pagenum;
            tDocmentDocModel.currpage = tTotalPage?tTotalPage:tDocmentDocModel.pagenum;
            [self addOrReplaceDocmentArray:tDocmentDocModel];
            
        }
        
        
        tIsWhiteBoardDealWith = true;
    }
    // to wb
    NSDictionary *tParamDic;
    if (self.isPlayback) {
        // 回放没有fromId
        tParamDic = @{
                            @"id":msgID,//DocumentFilePage_ShowPage
                            @"ts":@(ts),
                            @"data":tDataDic?tDataDic:[NSNull null],
                            @"name":msgName,//ShowPage
                            };
    } else {
        tParamDic = @{
                            @"id":msgID,//DocumentFilePage_ShowPage
                            @"ts":@(ts),
                            @"data":tDataDic?tDataDic:[NSNull null],
                            @"name":msgName,//ShowPage
                            @"fromID":fromId
                            };
    }
    
    
    NSString *tMessageString = add ?@"publish-message-received" :@"delete-message-received";
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tParamDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSString *jsReceivePhoneByTriggerEvent = [NSString stringWithFormat:@"GLOBAL.phone.receivePhoneByTriggerEvent('%@',%@)",tMessageString,jsonString];
    [_iBoardHandle.iWebView evaluateJavaScript:jsReceivePhoneByTriggerEvent completionHandler:^(id _Nullable id, NSError * _Nullable error) {
        
        NSLog(@"----GLOBAL.phone.receivePhoneByTriggerEvent");
    }];
   
    
    if (_iBoardDelegate && [_iBoardDelegate respondsToSelector:@selector(boardOnRemoteMsg:ID:Name:TS:Data:InList:)]) {
        
        tIsWhiteBoardDealWith = [_iBoardDelegate boardOnRemoteMsg:add ID:msgID Name:msgName TS:ts Data:data InList:inlist];
        
    }
    
    return tIsWhiteBoardDealWith;
}

- (TKDocmentDocModel *)resolveDocumentModelFromDic:(NSDictionary *)dic {
    
    /*
     isDynamicPPT = 0;
     isGeneralFile = 1;
     isH5Document = 0;
     */
    TKDocmentDocModel *tDocmentDocModel = [[TKDocmentDocModel alloc] init];
    [tDocmentDocModel setValuesForKeysWithDictionary:[dic valueForKey:@"filedata"]];
    tDocmentDocModel.dynamicppt = [dic objectForKey:@"isDynamicPPT"];
    tDocmentDocModel.action = [dic objectForKey:@"action"];
    tDocmentDocModel.type = [dic objectForKey:@"mediaType"];
    BOOL isDynamicPPT = [[dic objectForKey:@"isDynamicPPT"]boolValue];
    BOOL isGeneralFile = [[dic objectForKey:@"isGeneralFile"]boolValue];
    BOOL isH5Document = [[dic objectForKey:@"isH5Document"]boolValue];
    tDocmentDocModel.fileprop = @(0);
    if (isDynamicPPT) {
        tDocmentDocModel.fileprop = @(2);
    }
    if (isH5Document) {
        tDocmentDocModel.fileprop = @(3);
    }
    
    
    //0:表示普通文档　１－２动态ppt(1: 第一版动态ppt 2: 新版动态ppt ）  3:h5文档
   // @property (nonatomic, strong) NSNumber *fileprop;
    
//    tDocmentDocModel.dynamicppt = [dic objectForKey:@"isDynamicPPT"];
//    tDocmentDocModel.action = [dic objectForKey:@"action"];
//    tDocmentDocModel.type = [dic objectForKey:@"mediaType"];
    
    return tDocmentDocModel;
}

- (TKMediaDocModel *)resolveMediaModelFromDic:(NSDictionary *)dic {
    TKMediaDocModel *tMediaDocModel = [[TKMediaDocModel alloc] init];
    [tMediaDocModel setValuesForKeysWithDictionary:[dic valueForKey:@"filedata"]];
    tMediaDocModel.dynamicppt = [dic objectForKey:@"isDynamicPPT"];
    tMediaDocModel.action = [dic objectForKey:@"action"];
    tMediaDocModel.type = [dic objectForKey:@"mediaType"];
    BOOL isDynamicPPT = [[dic objectForKey:@"isDynamicPPT"]boolValue];
    BOOL isGeneralFile = [[dic objectForKey:@"isGeneralFile"]boolValue];
    BOOL isH5Document = [[dic objectForKey:@"isH5Document"]boolValue];
    tMediaDocModel.fileprop = @(0);
    if (isDynamicPPT) {
        tMediaDocModel.fileprop = @(2);
    }
    if (isH5Document) {
        tMediaDocModel.fileprop = @(3);
    }
//    tMediaDocModel.action = [dic objectForKey:@"action"];
//    tMediaDocModel.type = [dic objectForKey:@"mediaType"];
    
    return tMediaDocModel;
}

#pragma mark 其他
//聊天信息
- (NSArray *)messageList {
    return [_iMessageList copy];
}
- (void)addOrReplaceMessage:(TKChatMessageModel *)aMessageModel {
    NSArray *tArray  = [_iMessageList copy];
    
    BOOL tIsHave = NO;
    NSInteger tIndex = 0;
    for (TKChatMessageModel *tChatMessageModel in tArray) {
        if ([tChatMessageModel.iMessage isEqualToString:aMessageModel.iMessage]&&[tChatMessageModel.iTime isEqualToString:aMessageModel.iTime]) {
            tIsHave = YES;
            [_iMessageList replaceObjectAtIndex:tIndex withObject:aMessageModel];
            
        }
        tIndex ++;
    }
    if (!tIsHave) {
        [_iMessageList addObject:aMessageModel];
    }
    
    
}
//user
- (NSArray *)userArray{
    return [_iUserList copy];
}
- (void)addUser:(RoomUser *)aRoomUser{
    [_iUserList addObject:aRoomUser];
}
- (void)delUser:(RoomUser *)aRoomUser{
    [_iUserList removeObject:aRoomUser];
}
//用户
- (NSArray *)userStdntAndTchrArray{
     return [_iUserStdAndTchrList copy];
}
- (void)addUserStdntAndTchr:(RoomUser *)aRoomUser {
    NSArray *tArray  = [_iUserStdAndTchrList copy];
    
    BOOL tIsHave                              = NO;
    BOOL tIsHaveTeacher                       = NO;
    NSInteger tRoomUserIndex = 0;
  
    for (RoomUser *tRoomUser in tArray) {
        if (tRoomUser.role == UserType_Teacher) {
            tIsHaveTeacher = YES;
            break;
            
        }
    }

    for (RoomUser *tRoomUser in tArray) {
        
        if ([tRoomUser.peerID isEqualToString:aRoomUser.peerID]) {
            
            tIsHave = YES;
            break;
            
        }
        tRoomUserIndex++;
        
    }
    
    if (!tIsHave) {
        
        if (aRoomUser.role == UserType_Teacher) {
            _iTeacherUser = aRoomUser;
            [_iUserStdAndTchrList insertObject:aRoomUser atIndex:0];
        }else if ([aRoomUser.peerID isEqualToString: self.localUser.peerID]){
            
             [_iUserStdAndTchrList insertObject:aRoomUser atIndex:tIsHaveTeacher];
           
        }else{
            [_iUserStdAndTchrList addObject:aRoomUser];
        }
        
    }else{
        
        [_iUserStdAndTchrList replaceObjectAtIndex:tRoomUserIndex withObject:aRoomUser];
        
    }
}
- (void)delUserStdntAndTchr:(RoomUser *)aRoomUser {
   
    NSArray *tArrayAll = [_iUserStdAndTchrList copy];
    NSInteger tRoomUserIndex = 0;
    for (RoomUser *tRoomUser in tArrayAll) {
        
        if ([tRoomUser.peerID isEqualToString:aRoomUser.peerID]) {
            [_iUserStdAndTchrList removeObjectAtIndex:tRoomUserIndex];
            break;
        }
        tRoomUserIndex ++;
    }

}
-(RoomUser *)userInUserList:(NSString*)peerId {
    
    NSArray *tArrayAll = [_iUserStdAndTchrList copy];
    for (RoomUser *tRoomUser in tArrayAll) {
        
        if ([tRoomUser.peerID isEqualToString:peerId]) {return tRoomUser;}
        
    }
    return nil;
    
}
//除了老师和巡课
- (NSArray *)userListExpecPtrlAndTchr{
    NSMutableArray *tUserArray = [[self userStdntAndTchrArray]mutableCopy];
    for (RoomUser *tUser in [self userStdntAndTchrArray]) {
        if (tUser.role == UserType_Teacher) {
            [tUserArray removeObject:tUser];
            break;
        }
    }
    NSDictionary *tDic =  [[TKEduSessionHandle shareInstance]secialUserDic];
    for (NSString *tPeer in tDic) {
        RoomUser *tUser  = [tDic objectForKey:tPeer];
        if (tUser.role != UserType_Patrol) {
             [tUserArray insertObject:tUser atIndex:0];
        }
       
    }
    return tUserArray;
}
//特殊用户，助教 寻课
-(void)addSecialUser:(RoomUser *)aRoomUser{
    [_iSpecialUserDic setObject:aRoomUser forKey:aRoomUser.peerID];
    
}

-(void)delSecialUser:(RoomUser*)aRoomUser{
    [_iSpecialUserDic removeObjectForKey:aRoomUser.peerID];
}

-(NSDictionary *)secialUserDic{
    return [_iSpecialUserDic copy];
}

//音频用户
- (NSSet *)userPlayAudioArray{
    
    return [_iUserPlayAudioArray copy];
    
}
- (void)addOrReplaceUserPlayAudioArray:(RoomUser *)aRoomUser {

    [_iUserPlayAudioArray addObject:aRoomUser.peerID];
}
- (void)delUserPlayAudioArray:(RoomUser *)aRoomUser {
    [_iUserPlayAudioArray removeObject:aRoomUser.peerID];
}

#pragma mark 白板数据
-(NSDictionary *)whiteBoardDic{
    
    NSNumber * companyid = @([self.iRoomProperties.iCompanyID integerValue]);
    
    NSNumber * fileprop = @(0);
    NSNumber * size =@(0);
    NSNumber * status = @(1);
    NSString *type = @"0";
    NSString * uploadtime = @"2017-08-31 16:41:23";
    NSString * uploaduserid = self.localUser.peerID;
    NSString * uploadusername = self.localUser.nickName;
    
    NSDictionary *tDic =  @{
                            @"active" :@(1),
                            
                            @"companyid":companyid,
                            @"fileprop" :fileprop,
                            @"size" :size,
                            @"status":status,
                            @"type":type,
                            @"uploadtime":uploadtime,
                            @"uploaduserid" :uploaduserid,
                            @"uploadusername" :uploadusername,
                            @"downloadpath":@"",
                            @"dynamicppt" :@(0),
                            @"fileid" :@(0),
                            @"filename":MTLocalized(@"Title.whiteBoard"),
                            @"filepath":@"",
                            @"fileserverid":@(0),
                            @"filetype" :@"whiteboard",
                            @"isconvert" :@(1),
                            @"newfilename":MTLocalized(@"Title.whiteBoard"),
                            @"pagenum" :@(1),
                            @"pdfpath":@"",
                            @"swfpath" :@"",
                            @"currpage":@(1)
                            };
    
    return tDic;
}

-(NSDictionary *)docmentDic{
    return [_iMediaMutableDic copy];
}
-(TKDocmentDocModel*)getDocmentFromFiledId:(NSString *)aFiledId{
    
    return [_iMediaMutableDic objectForKey:aFiledId];
}
- (NSArray *)docmentArray{
    
    return [_iDocmentMutableArray copy];
    
}
- (bool )addOrReplaceDocmentArray:(TKDocmentDocModel *)aDocmentDocModel {
   
    if (!aDocmentDocModel) {
        return false;
    }
    
    if ([aDocmentDocModel.dynamicppt integerValue]==1)
        return false;
    TKLog(@"---------add:%@",aDocmentDocModel.filename);
    NSArray *tArray  = [_iDocmentMutableArray copy];
    BOOL tIsHave     = NO;
    NSInteger tIndex = 0;
    for (TKDocmentDocModel *tDocmentDocModel in tArray) {
         BOOL isCurrntDM = [self isEqualFileId:tDocmentDocModel aSecondModel:aDocmentDocModel];
        if (isCurrntDM) {
            
            //active
            if ([aDocmentDocModel.active intValue]!= [tDocmentDocModel.active intValue] && aDocmentDocModel.active) {
                tDocmentDocModel.active = aDocmentDocModel.active;
            }
            //animation
            if ([aDocmentDocModel.animation intValue]!= [tDocmentDocModel.animation intValue] && aDocmentDocModel.animation) {
                tDocmentDocModel.animation = aDocmentDocModel.animation;
            }
            //companyid
            if ([aDocmentDocModel.companyid intValue]!= [tDocmentDocModel.companyid intValue] && aDocmentDocModel.companyid) {
                tDocmentDocModel.companyid = aDocmentDocModel.companyid;
            }
            
            //downloadpath
            if (![aDocmentDocModel.downloadpath isEqualToString:tDocmentDocModel.downloadpath] && aDocmentDocModel.downloadpath) {
                tDocmentDocModel.downloadpath = aDocmentDocModel.downloadpath;
            }
            //filename
            if (![aDocmentDocModel.filename isEqualToString:tDocmentDocModel.filename] && aDocmentDocModel.filename) {
                // 白板的名字不要修改 MTLocalized(@"Title.whiteBoard")
                if (![tDocmentDocModel.filetype isEqualToString:@"whiteboard"]) {
                    tDocmentDocModel.filename = aDocmentDocModel.filename;
                }
            }
            //fileid
            //filepath
            if (![aDocmentDocModel.filepath isEqualToString:tDocmentDocModel.filepath] && aDocmentDocModel.filepath) {
                tDocmentDocModel.filepath = aDocmentDocModel.filepath;
            }
            //fileserverid
            if ([aDocmentDocModel.fileserverid intValue]!= [tDocmentDocModel.fileserverid intValue] && aDocmentDocModel.fileserverid) {
                tDocmentDocModel.fileserverid = aDocmentDocModel.fileserverid;
            }
            //filetype
            if (![aDocmentDocModel.filetype isEqualToString:tDocmentDocModel.filetype] && aDocmentDocModel.filetype) {
                tDocmentDocModel.filetype = aDocmentDocModel.filetype;
            }
            //isconvert
            if ([aDocmentDocModel.isconvert intValue]!= [tDocmentDocModel.isconvert intValue] && aDocmentDocModel.isconvert) {
                tDocmentDocModel.isconvert = aDocmentDocModel.isconvert;
            }
            
            
            //newfilename
            if (![aDocmentDocModel.newfilename isEqualToString:tDocmentDocModel.newfilename] && aDocmentDocModel.newfilename) {
                tDocmentDocModel.newfilename = aDocmentDocModel.newfilename;
            }
            
            //pagenum
            if ([aDocmentDocModel.pagenum intValue]!= [tDocmentDocModel.pagenum intValue] && aDocmentDocModel.pagenum) {
                tDocmentDocModel.pagenum = aDocmentDocModel.pagenum;
            }
            //pdfpath
            if (![aDocmentDocModel.pdfpath isEqualToString:tDocmentDocModel.pdfpath] && aDocmentDocModel.pdfpath) {
                tDocmentDocModel.pdfpath = aDocmentDocModel.pdfpath;
            }
            
            //size
            if ([aDocmentDocModel.size intValue]!= [tDocmentDocModel.size intValue] && aDocmentDocModel.size) {
                tDocmentDocModel.size = aDocmentDocModel.size;
            }
            //status
            if ([aDocmentDocModel.status intValue]!= [tDocmentDocModel.status intValue] && aDocmentDocModel.status) {
                tDocmentDocModel.status = aDocmentDocModel.status;
            }
            //swfpath
            if (![aDocmentDocModel.swfpath isEqualToString:tDocmentDocModel.swfpath] && aDocmentDocModel.swfpath) {
                tDocmentDocModel.swfpath = aDocmentDocModel.swfpath;
            }
            //type
            if (![aDocmentDocModel.type isEqualToString:tDocmentDocModel.type] && aDocmentDocModel.type) {
                tDocmentDocModel.type = aDocmentDocModel.type;
            }
            //uploadtime
            if (![aDocmentDocModel.uploadtime isEqualToString:tDocmentDocModel.uploadtime] && aDocmentDocModel.uploadtime) {
                tDocmentDocModel.uploadtime = aDocmentDocModel.uploadtime;
            }
            
            //status
            if ([aDocmentDocModel.uploaduserid intValue]!= [tDocmentDocModel.uploaduserid intValue] && aDocmentDocModel.uploaduserid) {
                tDocmentDocModel.uploaduserid = aDocmentDocModel.uploaduserid;
            }
            //uploadtime
            if (![aDocmentDocModel.uploadusername isEqualToString:tDocmentDocModel.uploadusername] && aDocmentDocModel.uploadusername) {
                tDocmentDocModel.uploadusername = aDocmentDocModel.uploadusername;
            }
            //currpage
            if ([aDocmentDocModel.currpage intValue]!= [tDocmentDocModel.currpage intValue] && aDocmentDocModel.currpage) {
                tDocmentDocModel.currpage = aDocmentDocModel.currpage;
            }
            
            //dynamicppt
            if ([aDocmentDocModel.dynamicppt intValue]!= [tDocmentDocModel.dynamicppt intValue] && aDocmentDocModel.dynamicppt) {
                tDocmentDocModel.dynamicppt = aDocmentDocModel.dynamicppt;
            }
            
            //pptslide
            if ([aDocmentDocModel.pptslide intValue]!= [tDocmentDocModel.pptslide intValue] && aDocmentDocModel.pptslide) {
                tDocmentDocModel.pptslide = aDocmentDocModel.pptslide;
            }
            
            //pptstep
            if ([aDocmentDocModel.pptstep intValue]!= [tDocmentDocModel.pptstep intValue] && aDocmentDocModel.pptstep) {
                tDocmentDocModel.pptstep = aDocmentDocModel.pptstep;
            }
            
            //action
            if (![aDocmentDocModel.action isEqualToString:tDocmentDocModel.action] && aDocmentDocModel.action) {
                tDocmentDocModel.action = aDocmentDocModel.action;
            }
            //isShow
            if ([aDocmentDocModel.isShow intValue]!= [tDocmentDocModel.isShow intValue] && aDocmentDocModel.isShow) {
                tDocmentDocModel.isShow = aDocmentDocModel.isShow;
            }
            aDocmentDocModel = tDocmentDocModel;
            tIsHave = YES;
            
            break;
        }
        tIndex++;
        
        
    }
    if (!tIsHave) {
        [_iDocmentMutableArray addObject:aDocmentDocModel];
        
    }else{
        [_iDocmentMutableArray replaceObjectAtIndex:tIndex withObject:aDocmentDocModel];
    }
    [_iDocmentMutableDic setObject:aDocmentDocModel forKey:[NSString stringWithFormat:@"%@",aDocmentDocModel.fileid]];
    
    return YES;
    
    
}
- (void)delDocmentArray:(TKDocmentDocModel *)aDocmentDocModel {
    if (!aDocmentDocModel) {
        return;
    }
    TKLog(@"---------del:%@",aDocmentDocModel.filename);
    
    NSArray *tArrayAll = [_iDocmentMutableArray copy];
    NSInteger tIndex = 0;
    for (TKDocmentDocModel *tDocmentDocModel in tArrayAll) {
        BOOL isCurrentDocment = [self isEqualFileId:tDocmentDocModel aSecondModel:aDocmentDocModel];
        if (isCurrentDocment) {
            [_iDocmentMutableArray removeObjectAtIndex:tIndex];
            
            break;
        }
        tIndex++;
        
    }
    [_iDocmentMutableDic removeObjectForKey:[NSString stringWithFormat:@"%@",aDocmentDocModel.fileid]];
    
    
}
//音视频
-(NSDictionary *)meidaDic{
    return [_iMediaMutableDic copy];
}
-(TKMediaDocModel*)getMediaFromFiledId:(NSString *)aFiledId{
    
    return [_iMediaMutableDic objectForKey:aFiledId];
}

- (NSArray *)mediaArray{
    
    
    return [_iMediaMutableArray copy];
    
}
- (void)addOrReplaceMediaArray:(TKMediaDocModel *)aMediaDocModel {
    if (!aMediaDocModel) {
        return ;
    }
    //TKLog(@"---------add:%@",aMediaDocModel.filename);
    NSArray *tArray  = [_iMediaMutableArray copy];
    
    BOOL tIsHave                              = NO;
    NSInteger tIndex = 0;
    for (TKMediaDocModel *tMediaDocModel in tArray) {
         BOOL isCurrentDocment = [self isEqualFileId:tMediaDocModel aSecondModel:aMediaDocModel];
        if (isCurrentDocment) {
            //page
            if ([aMediaDocModel.page intValue]!= [tMediaDocModel.page intValue] && aMediaDocModel.page) {
                tMediaDocModel .page = aMediaDocModel.page ;
            }
            //ismedia
            if ([aMediaDocModel.ismedia intValue]!= [tMediaDocModel.ismedia intValue] && aMediaDocModel.ismedia) {
                tMediaDocModel .ismedia = aMediaDocModel.ismedia ;
            }
            //isconvert
            if ([aMediaDocModel.isconvert intValue]!= [tMediaDocModel.isconvert intValue] && aMediaDocModel.isconvert) {
                tMediaDocModel .isconvert = aMediaDocModel.isconvert ;
            }
            
            //pagenum
            if ([aMediaDocModel.pagenum intValue]!= [tMediaDocModel.pagenum intValue] && aMediaDocModel.pagenum) {
                tMediaDocModel .pagenum = aMediaDocModel.pagenum ;
            }
            //filetype
            if (![aMediaDocModel.filetype isEqualToString:tMediaDocModel.filetype] && aMediaDocModel.filetype) {
                
                tMediaDocModel.filetype = aMediaDocModel.filetype;
                
            }
            
            //filename
            if (![aMediaDocModel.filename isEqualToString:tMediaDocModel.filename] && aMediaDocModel.filename) {
                
                tMediaDocModel.filename = aMediaDocModel.filename;
                
            }
            //filename
            if (![aMediaDocModel.swfpath isEqualToString:tMediaDocModel.swfpath] && aMediaDocModel.swfpath) {
                
                tMediaDocModel.swfpath = aMediaDocModel.swfpath;
                
            }
            //currentTime
            if ([aMediaDocModel.currentTime intValue]!= [tMediaDocModel.currentTime intValue] && aMediaDocModel.currentTime) {
                tMediaDocModel.currentTime = aMediaDocModel.currentTime ;
            }
            //isPlay
            if ([aMediaDocModel.isPlay intValue]!= [tMediaDocModel.isPlay intValue] && aMediaDocModel.isPlay) {
                tMediaDocModel.isPlay = aMediaDocModel.isPlay ;
            }
            
            aMediaDocModel = tMediaDocModel;
            tIsHave = YES;
            
            break;
        }
        tIndex++;
        
        
    }
    if (!tIsHave) {
        [_iMediaMutableArray addObject:aMediaDocModel];
        
    }else{
        [_iMediaMutableArray replaceObjectAtIndex:tIndex withObject:aMediaDocModel];
    }
    [_iMediaMutableDic setObject:aMediaDocModel forKey:[NSString stringWithFormat:@"%@",aMediaDocModel.fileid]];
    
    
    
    
}
- (void)delMediaArray:(TKMediaDocModel *)aMediaDocModel {
    if (!aMediaDocModel) {
        return ;
    }
    TKLog(@"---------del:%@",aMediaDocModel.filename);
    [_iMediaMutableDic setObject:aMediaDocModel forKey:[NSString stringWithFormat:@"%@",aMediaDocModel.fileid]];
    //删除所有
    NSArray *tArrayAll = [_iMediaMutableArray copy];
    NSInteger tIndex = 0;
    for (TKMediaDocModel *tMediaDocModel in tArrayAll) {
        BOOL isCurrentDocment = [self isEqualFileId:tMediaDocModel aSecondModel:aMediaDocModel];
        if (isCurrentDocment) {
            [_iMediaMutableArray removeObjectAtIndex:tIndex];
            break;
        }
        tIndex++;
        
    }
    
}
-(TKDocmentDocModel *)getNextDocment:(TKDocmentDocModel *)aCurrentDocmentModel{
    NSArray *tArray = [self docmentArray];
    int i = 0;
    for (TKDocmentDocModel *tDoc in tArray)
    {
         BOOL isCurrentDocment = [self isEqualFileId:tDoc aSecondModel:aCurrentDocmentModel];
        if(isCurrentDocment)
        {
            NSInteger tIndex = (i == [tArray count]-1)?i-1:i+1;
            if (tIndex<0) {tIndex = 0;}
            return [tArray objectAtIndex:tIndex];
            
        }
        i++;
    }
    return [tArray objectAtIndex:0];
    
}
-(TKMediaDocModel*)getNextMedia:(TKMediaDocModel *)aCurrentMediaDocModel{
    NSArray *tArray = [self mediaArray];
    int i = 0;
    for (TKMediaDocModel *tDoc in tArray)
    {
        BOOL isCurrentDocment = [self isEqualFileId:tDoc aSecondModel:aCurrentMediaDocModel];
        if(isCurrentDocment)
            
        {
            NSInteger tIndex = (i == [tArray count]-1)?i-1:i+1;
            if (tIndex<0) {tIndex = 0;}
            return [tArray objectAtIndex:tIndex];
            
        }
        i++;
    }
    return [tArray objectAtIndex:0];
}

-(BOOL)isEqualFileId:(id)aModel  aSecondModel:(id)aSecondModel{
    BOOL isEqual = NO;
   
    if ([aModel isKindOfClass:[TKDocmentDocModel class]] && [aSecondModel isKindOfClass:[TKDocmentDocModel class]]) {
        TKDocmentDocModel *tDoc = (TKDocmentDocModel*)aModel;
        TKDocmentDocModel *tDoc2 = (TKDocmentDocModel*)aSecondModel;
        NSString *tFileid = [NSString stringWithFormat:@"%@",tDoc.fileid];
        NSString *tCurrentFileid = [NSString stringWithFormat:@"%@",tDoc2.fileid];
        isEqual = [tFileid isEqualToString:tCurrentFileid];
    }
    
    if ([aModel isKindOfClass:[TKMediaDocModel class]] && [aSecondModel isKindOfClass:[TKMediaDocModel class]]) {
        TKMediaDocModel *tDoc = (TKMediaDocModel*)aModel;
        TKMediaDocModel *tDoc2 = (TKMediaDocModel*)aSecondModel;
        NSString *tFileid = [NSString stringWithFormat:@"%@",tDoc.fileid];
        NSString *tCurrentFileid = [NSString stringWithFormat:@"%@",tDoc2.fileid];
        isEqual = [tFileid isEqualToString:tCurrentFileid];
    }
    return  isEqual;
}
#pragma mark 加按钮
//-(bool)addPendingUser:(RoomUser *)aRoomUser{
//    int tMaxVideo = [self.iRoomProperties.iMaxVideo intValue];
//    // (tMaxVideo-1)，因为老师也需要占一路流
//    if ((tMaxVideo-1) > [_iPendingButtonDic count]) {
//        [_iPendingButtonDic setObject:aRoomUser forKey:aRoomUser.peerID];
//        TKLog(@"pending--- add pending user: %@, %@", aRoomUser.nickName, aRoomUser.peerID);
//        return  true;
//    }
//    return false;
//}

-(bool)addPendingUser:(RoomUser *)aRoomUser{
    int tMaxVideo = [self.iRoomProperties.iMaxVideo intValue];
    // (tMaxVideo-1)，因为老师也需要占一路流
    NSLog(@"-----pend before:pengding dic count: %ld", _iPendingButtonDic.count);
    NSLog(@"-----pend before:rest count: %ld", tMaxVideo - [TKEduSessionHandle shareInstance].iPublishDic.count);
    if ((tMaxVideo-[TKEduSessionHandle shareInstance].iPublishDic.count) > [_iPendingButtonDic count]) {
        [_iPendingButtonDic setObject:aRoomUser forKey:aRoomUser.peerID];
        //TKLog(@"pending--- add pending user: %@, %@", aRoomUser.nickName, aRoomUser.peerID);
        
        NSLog(@"-----pend after:pengding dic count: %ld", _iPendingButtonDic.count);
        NSLog(@"-----pend after:rest count: %ld", tMaxVideo - [TKEduSessionHandle shareInstance].iPublishDic.count);
        return  true;
    }

    NSLog(@"-----pend after:pengding dic count: %ld", _iPendingButtonDic.count);
    NSLog(@"-----pend after:rest count: %ld", tMaxVideo - [TKEduSessionHandle shareInstance].iPublishDic.count);
    return false;
}
-(void)delePendingUser:(RoomUser*)aRoomUser{
    if (aRoomUser) {
        [_iPendingButtonDic removeObjectForKey:aRoomUser.peerID];
        TKLog(@"pending--- remove pending user: %@, %@", aRoomUser.nickName, aRoomUser.peerID);
    }
}

-(NSDictionary *)pendingUserDic{
    return [_iPendingButtonDic copy];
}
#pragma mark 发布
-(void)addPublishUser:(RoomUser *)aRoomUser{
    [_iPublishDic setObject:aRoomUser forKey:aRoomUser.peerID];
    // 当助教发布音视频时，也要将_iHasPublishStd设置为YES
    if (aRoomUser.role == UserType_Student || aRoomUser.role == UserType_Assistant) {
        _iHasPublishStd = YES;
    }
    
    
}

-(void)delePublishUser:(RoomUser*)aRoomUser{
    [_iPublishDic removeObjectForKey:aRoomUser.peerID];
    if (_iPublishDic.count == 0) {
        _iHasPublishStd = NO;
    }
    if (_iPublishDic.count == 1) {
        [_iPublishDic enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, RoomUser *  _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.role == UserType_Student || obj.role == UserType_Assistant) {
                // 当助教发布音视频时，也要将_iHasPublishStd设置为YES
                _iHasPublishStd = YES;
                *stop = YES;
            }else{
                _iHasPublishStd = NO;
            }
           
            
        }];
    }
}

-(NSDictionary *)publishUserDic{
    return [_iPublishDic copy];
}


#pragma mark 未发布
-(void)addUnPublishUser:(RoomUser *)aRoomUser{
    [_iUnPublisDic setObject:aRoomUser forKey:aRoomUser.peerID];
    
}

-(void)deleUnPublishUser:(RoomUser*)aRoomUser{
    [_iUnPublisDic removeObjectForKey:aRoomUser.peerID];
}

-(NSDictionary *)unpublishUserDic{
    return [_iUnPublisDic copy];
}

-(void)clearMessageList {
    [_iMessageList removeAllObjects];
}

-(void)clearAllClassData{
    
     //修复重连时，会有问题！
    [_iMessageList removeAllObjects];
    [_iUserList removeAllObjects];
    [_iUserStdAndTchrList removeAllObjects];
    [_iUserPlayAudioArray removeAllObjects];
    _isClassBegin = NO;
    _isMuteAudio  = NO;
    _iTeacherUser = nil;
    //_iRoomProperties = nil;     // 断线重连阶段没有获取checkroom的过程，所以清理掉iRoomProperties会有影响
    [_iPendingButtonDic removeAllObjects];

    _iIsPlaying = NO;
    _isPlayMedia = NO;
    _isLocal = NO;
    _isChangeMedia = NO;
    _iHasPublishStd = NO;
    _iStdOutBottom = NO;
    _iIsFullState = NO;
    
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
}
-(void)clearView{
    _iMediaListView = nil;
    _iDocumentListView = nil;
}
#pragma mark set and get

-(RoomUser*)localUser{
    return [_roomMgr localUser];
}
-(NSSet *)remoteUsers{
    return [_roomMgr remoteUsers];
}

-(BOOL)useFrontCamera{
    return [_roomMgr useFrontCamera];
}

-(BOOL)isConnected{
    return [_roomMgr isConnected];
}
-(BOOL)isJoined{
    return [_roomMgr isJoined];
}
-(NSString *)roomName{
    return [_roomMgr roomName];
}
-(int)roomType{
    return [_roomMgr roomType];
}
-(NSDictionary *)roomProperties{
    return  [_roomMgr roomProperties];
}


#pragma mark 发布影音
-(void)publishtMediaDocModel:(TKMediaDocModel*)aMediaDocModel add:(BOOL)add To:(NSString *)to{
  //mediaType\":\"video\"
    BOOL tIsVideo = [TKUtil isVideo:aMediaDocModel.filetype];
    NSString *tIdString = tIsVideo?sVideo_MediaFilePage_ShowPage:sAudio_MediaFilePage_ShowPage ;
    NSDictionary *tMediaDocModelDic = [self fileDataDic:aMediaDocModel ismedia:YES];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tMediaDocModelDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    //to = sTellAllExpectSender;
    if (add) {
        //[self sessionHandlePubMsg:sShowPage ID:tIdString To:to Data:jsonString Save:true completion:nil];
        [self sessionHandlePubMsg:sShowPage ID:tIdString To:to Data:jsonString Save:true AssociatedMsgID:nil AssociatedUserID:nil completion:nil];
    }else{
        [self sessionHandleDelMsg:sShowPage ID:tIdString To:to Data:jsonString completion:nil];
    }
}

-(void)publishVideoDragWithDic:(NSDictionary * )aVideoDic To:(NSString *)to {
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:aVideoDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    //[self sessionHandlePubMsg:sVideoDraghandle ID:sVideoDraghandle To:to Data:jsonString Save:true completion:nil];
    [self sessionHandlePubMsg:sVideoDraghandle ID:sVideoDraghandle To:to Data:jsonString Save:true AssociatedMsgID:nil AssociatedUserID:nil completion:nil];
}
#pragma mark 发布文档
-(void)publishtDocMentDocModel:(TKDocmentDocModel*)tDocmentDocModel To:(NSString *)to aTellLocal:(BOOL)aTellLocal{
    if (aTellLocal) {
        [self docmentDefault:tDocmentDocModel];
    }
    
    NSDictionary *tDocmentDocModelDic  =  [self fileDataDic:tDocmentDocModel ismedia:NO];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tDocmentDocModelDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    //[self sessionHandlePubMsg:sShowPage ID:sDocumentFilePage_ShowPage To:to Data:jsonString Save:true completion:nil];
    [self sessionHandlePubMsg:sShowPage ID:sDocumentFilePage_ShowPage To:to Data:jsonString Save:true AssociatedMsgID:nil AssociatedUserID:nil completion:nil];
}
#pragma mark 删除文档

-(NSDictionary *)fileDataChangeDic:(id)aDefaultDocment isDel:(BOOL)isDel ismedia:(BOOL)ismedia{
    NSDictionary *tDic = ismedia?[self fileDataMediaChangeDic:(TKMediaDocModel *)aDefaultDocment isDel:isDel]:[self fileDataDocChangeDic:(TKDocmentDocModel *)aDefaultDocment isDel:isDel];
    return tDic;
}

-(NSDictionary *)fileDataDocChangeDic:(TKDocmentDocModel *)aDefaultDocment isDel:(BOOL)isDel{
    //0:表示普通文档　１－２动态ppt(1: 第一版动态ppt 2: 新版动态ppt ）  3:h5文档
    NSString *tFileProp = [NSString stringWithFormat:@"%@",aDefaultDocment.fileprop];
    NSNumber* isGeneralFile = [tFileProp isEqualToString:@"0"]?@(true):@(false);
    NSNumber* isDynamicPPT  = ([tFileProp isEqualToString:@"1"] ||[tFileProp isEqualToString:@"2"] )?@(true):@(false);
    NSNumber* isH5Document   = [tFileProp isEqualToString:@"3"]?@(true):@(false);
    NSString *action        =  isDynamicPPT?sActionShow:@"";
    NSString *mediaType     =  @"";
    NSDictionary *tDataDic = @{
                               @"isDel":@(isDel),
                               @"isGeneralFile":isGeneralFile,
                               @"isDynamicPPT":isDynamicPPT,
                               @"isH5Document":isH5Document,
                               @"action":action,
                               @"mediaType":mediaType,
                               @"isMedia":@(false),
                               @"filedata":@{
                                       @"fileid":aDefaultDocment.fileid?aDefaultDocment.fileid:@(0),
                                       @"filename":aDefaultDocment.filename?aDefaultDocment.filename:@"",
                                       @"filetype": aDefaultDocment.filetype?aDefaultDocment.filetype:@"",
                                       @"currpage": aDefaultDocment.currpage?aDefaultDocment.currpage:@(1),
                                       @"pagenum"  : aDefaultDocment.pagenum?aDefaultDocment.pagenum:@"",
                                       @"pptslide": aDefaultDocment.pptslide?aDefaultDocment.pptslide:@(1),
                                       @"pptstep":aDefaultDocment.pptstep?aDefaultDocment.pptstep:@(0),
                                       @"steptotal":aDefaultDocment.steptotal?aDefaultDocment.steptotal:@(0),
                                       @"swfpath"  :  aDefaultDocment.swfpath?aDefaultDocment.swfpath:@""
                                       }
                               };
    return tDataDic;
    
}
-(NSDictionary *)fileDataMediaChangeDic:(TKMediaDocModel *)aDefaultDocment isDel:(BOOL)isDel{
    
    
    //0:表示普通文档　１－２动态ppt(1: 第一版动态ppt 2: 新版动态ppt ）  3:h5文档
    NSString *tFileProp = [NSString stringWithFormat:@"%@",aDefaultDocment.fileprop];
    NSNumber* isGeneralFile = [tFileProp isEqualToString:@"0"]?@(true):@(false);
    NSNumber* isDynamicPPT  = ([tFileProp isEqualToString:@"1"] ||[tFileProp isEqualToString:@"2"] )?@(true):@(false);
    NSNumber* isH5Document   = [tFileProp isEqualToString:@"3"]?@(true):@(false);
    NSString *action        =  isDynamicPPT?sActionShow:@"";
    BOOL tIsVideo = [TKUtil isVideo:aDefaultDocment.filetype];
    NSString *mediaType = tIsVideo?@"video":@"audio" ;
    NSDictionary *tDataDic = @{
                               @"isDel":@(isDel),
                               @"isGeneralFile":isGeneralFile,
                               @"isDynamicPPT":isDynamicPPT,
                               @"isH5Document":isH5Document,
                               @"action":action,
                               @"mediaType":mediaType,
                               @"isMedia":@(true),
                               @"filedata":@{
                                       @"fileid":aDefaultDocment.fileid?aDefaultDocment.fileid:@(0),
                                       @"filename":aDefaultDocment.filename?aDefaultDocment.filename:@"",
                                       @"filetype": aDefaultDocment.filetype?aDefaultDocment.filetype:@"",
                                       @"currpage": aDefaultDocment.currpage?aDefaultDocment.currpage:@(1),
                                       @"pagenum"  : aDefaultDocment.pagenum?aDefaultDocment.pagenum:@"",
                                       @"pptslide": aDefaultDocment.pptslide?aDefaultDocment.pptslide:@(1),
                                       @"pptstep":aDefaultDocment.pptstep?aDefaultDocment.pptstep:@(0),
                                       @"steptotal":aDefaultDocment.steptotal?aDefaultDocment.steptotal:@(0),
                                       @"swfpath"  :  aDefaultDocment.swfpath?aDefaultDocment.swfpath:@""
                                       }
                               };
    return tDataDic;
    
}
-(void)addDocMentDocModel:(TKDocmentDocModel*)aDocmentDocModel To:(NSString *)to{
    NSDictionary *tDocmentDocModelDic = [self fileDataChangeDic:aDocmentDocModel isDel:false ismedia:false];
    //改成字符串
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tDocmentDocModelDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    //[self sessionHandlePubMsg:sDocumentChange ID:sDocumentChange To:to Data:jsonString Save:true completion:nil];
    [self sessionHandlePubMsg:sDocumentChange ID:sDocumentChange To:to Data:jsonString Save:true AssociatedMsgID:nil AssociatedUserID:nil completion:nil];
}
//todo
-(void)deleteDocMentDocModel:(TKDocmentDocModel*)aDocmentDocModel To:(NSString *)to{

    NSDictionary *tDocmentDocModelDic = [self fileDataChangeDic:aDocmentDocModel isDel:true ismedia:false];
    //改成字符串
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tDocmentDocModelDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    //[self sessionHandlePubMsg:sDocumentChange ID:sDocumentChange To:to Data:jsonString Save:true completion:nil];
    [self sessionHandlePubMsg:sDocumentChange ID:sDocumentChange To:to Data:jsonString Save:true AssociatedMsgID:nil AssociatedUserID:nil completion:nil];
    
}
-(void)deleteaMediaDocModel:(TKMediaDocModel*)aMediaDocModel To:(NSString *)to{
    
     NSDictionary *tMediaDocModelDic = [self fileDataChangeDic:aMediaDocModel isDel:true ismedia:true];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tMediaDocModelDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    //[self sessionHandlePubMsg:sDocumentChange ID:sDocumentChange To:to Data:jsonString Save:true completion:nil];
    [self sessionHandlePubMsg:sDocumentChange ID:sDocumentChange To:to Data:jsonString Save:true AssociatedMsgID:nil AssociatedUserID:nil completion:nil];
    
}

#pragma mark 设置白板

- (void)fileListResetToDefault {
    for (TKDocmentDocModel *model in _iDocmentMutableArray) {
        [model resetToDefault];
    }
}

-(NSDictionary *)fileDataDic:(id )aDefaultDocment ismedia:(BOOL)ismedia{
    NSDictionary *tDic = ismedia?[self fileDataMediaDic:(TKMediaDocModel *)aDefaultDocment ]:[self fileDataDocDic:(TKDocmentDocModel *)aDefaultDocment ];
    return tDic;
}


-(NSDictionary *)fileDataDocDic:(TKDocmentDocModel *)aDefaultDocment {
    
    if (!aDefaultDocment) {
        //白板
    NSDictionary *tDataDic = @{
                                   @"isGeneralFile":@(true),
                                   @"isDynamicPPT":@(false),
                                   @"isH5Document":@(false),
                                   @"action":@"",
                                   @"fileid":@(0),
                                   @"mediaType":@"",
                                   @"isMedia":@(0),
                                   @"filedata":@{
                                           @"fileid"   :@(0),
                                           @"filename" :MTLocalized(@"Title.whiteBoard"),
                                           @"filetype" :MTLocalized(@"Title.whiteBoard"),
                                           @"currpage" :@(1),
                                           @"pagenum"  :@(1),
                                           @"pptslide" :@(1),
                                           @"pptstep"  :@(0),
                                           @"steptotal":@(0),
                                           @"swfpath"  :@""
                                           }
                            };
        return tDataDic;
    }
    //isH5Document isH5Docment
    //0:表示普通文档　１－２动态ppt(1: 第一版动态ppt 2: 新版动态ppt ）  3:h5文档
    NSString *tFileProp = [NSString stringWithFormat:@"%@",aDefaultDocment.fileprop];
    NSNumber* isGeneralFile = [tFileProp isEqualToString:@"0"]?@(true):@(false);
    NSNumber* isDynamicPPT  = ([tFileProp isEqualToString:@"1"] ||[tFileProp isEqualToString:@"2"] )?@(true):@(false);
    NSNumber* isH5Document   = [tFileProp isEqualToString:@"3"]?@(true):@(false);
    NSString *action        =  isDynamicPPT?sActionShow:@"";
              action        =  isH5Document?sActionShow:@"";
    NSString *mediaType     =  @"";
    NSDictionary *tDataDic = @{
                               @"isGeneralFile":isGeneralFile,
                               @"isDynamicPPT":isDynamicPPT,
                               @"isH5Document":isH5Document,
                               @"action":action,
                               @"fileid":aDefaultDocment.fileid?aDefaultDocment.fileid:@(0),
                               @"mediaType":mediaType,
                               @"isMedia":@(0),
                               @"filedata":@{
                                       @"fileid":aDefaultDocment.fileid?aDefaultDocment.fileid:@(0),
                                       @"filename":aDefaultDocment.filename?aDefaultDocment.filename:@"",
                                       @"filetype": aDefaultDocment.filetype?aDefaultDocment.filetype:@"",
                                       
                                       @"currpage": aDefaultDocment.currpage?aDefaultDocment.currpage:@(1),
                                       @"pagenum"  : aDefaultDocment.pagenum?aDefaultDocment.pagenum:@"",
                                       @"pptslide": aDefaultDocment.pptslide?aDefaultDocment.pptslide:@(1),
                                       @"pptstep":aDefaultDocment.pptstep?aDefaultDocment.pptstep:@(0),
                                       @"steptotal":aDefaultDocment.steptotal?aDefaultDocment.steptotal:@(0),
                                       @"swfpath"  :  aDefaultDocment.swfpath?aDefaultDocment.swfpath:@""
                                       }
                               };
    return tDataDic;

}
-(NSDictionary *)fileDataMediaDic:(TKMediaDocModel *)aDefaultDocment {
    
    //0:表示普通文档　１－２动态ppt(1: 第一版动态ppt 2: 新版动态ppt ）  3:h5文档
    NSString *tFileProp = [NSString stringWithFormat:@"%@",aDefaultDocment.fileprop];
    NSNumber* isGeneralFile = [tFileProp isEqualToString:@"0"]?@(true):@(false);
    NSNumber* isDynamicPPT  = ([tFileProp isEqualToString:@"1"] ||[tFileProp isEqualToString:@"2"] )?@(true):@(false);
    NSNumber* isH5Document   = [tFileProp isEqualToString:@"3"]?@(true):@(false);
    NSString *action        =  isDynamicPPT?sActionShow:@"";
    BOOL tIsVideo = [TKUtil isVideo:aDefaultDocment.filetype];
    NSString *mediaType = tIsVideo?@"video":@"audio" ;
   
    NSDictionary *tDataDic = @{
                               @"isGeneralFile":isGeneralFile,
                               @"isDynamicPPT":isDynamicPPT,
                               @"isH5Document":isH5Document,
                               @"action":action,
                               @"fileid":aDefaultDocment.fileid?aDefaultDocment.fileid:@(0),
                               @"mediaType":mediaType,
                               @"isMedia":@(1),
                               @"filedata":@{
                                       @"fileid":aDefaultDocment.fileid?aDefaultDocment.fileid:@(0),
                                       @"filename":aDefaultDocment.filename?aDefaultDocment.filename:@"",
                                       @"filetype": aDefaultDocment.filetype?aDefaultDocment.filetype:@"",
                                       
                                       @"currpage": aDefaultDocment.currpage?aDefaultDocment.currpage:@(1),
                                       @"pagenum"  : aDefaultDocment.pagenum?aDefaultDocment.pagenum:@"",
                                       @"pptslide": aDefaultDocment.pptslide?aDefaultDocment.pptslide:@(1),
                                       @"pptstep":aDefaultDocment.pptstep?aDefaultDocment.pptstep:@(0),
                                       @"steptotal":aDefaultDocment.steptotal?aDefaultDocment.steptotal:@(0),
                                       @"swfpath"  :  aDefaultDocment.swfpath?aDefaultDocment.swfpath:@""
                                       }
                               };
    return tDataDic;
    
}
-(void)docmentDefault:(TKDocmentDocModel*)aDefaultDocment{

    _iCurrentDocmentModel = aDefaultDocment;
    NSDictionary *tDataDic =  [self fileDataDic:aDefaultDocment ismedia:NO];
    NSDictionary *tParamDicDefault = @{
                                       @"id":sDocumentFilePage_ShowPage,//DocumentFilePage_ShowPage
                                       @"ts":@(0),
                                       @"data":tDataDic?tDataDic:[NSNull null],
                                       @"name":sShowPage
                                       };
    
    NSString *tMessageString = @"publish-message-received";
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tParamDicDefault options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSString *jsReceivePhoneByTriggerEventForDefault = [NSString stringWithFormat:@"GLOBAL.phone.receivePhoneByTriggerEvent('%@',%@)",tMessageString,jsonString];
    [_iBoardHandle.iWebView evaluateJavaScript:jsReceivePhoneByTriggerEventForDefault completionHandler:^(id _Nullable id, NSError * _Nullable error) {
        NSLog(@"----GLOBAL.phone.receivePhoneByTriggerEvent");
    }];
}
-(void)clearAllWhiteBoardData{
    
    [_iDocmentMutableArray removeAllObjects];
    [_iMediaMutableArray removeAllObjects];       
    [_iMediaMutableDic removeAllObjects];
    [_iDocmentMutableDic removeAllObjects];
    _iDefaultDocment         = nil;
    _iIsPlaying              = NO;
    _isPlayMedia             = NO;
    _iHasPublishStd          = NO;
    _iStdOutBottom           = NO;
    _iIsFullState            = NO;
    _isLocal                 = NO;
    _iCurrentDocmentModel    = nil;
    _iPreDocmentModel        = nil;
    _iPreMediaDocModel       = nil;
    _iCurrentMediaDocModel   = nil;

}

-(void)configurePlayerRoute:(BOOL)aIsPlay isCancle:(BOOL)isCancle{
//    if ([TKEduSessionHandle shareInstance].isHeadphones) {
//        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
//        return;
//    }
    
    if (isCancle) {
        [[AVAudioSession sharedInstance]setActive:NO error:nil];
        return;
    }
    
     [self sessionHandleUseLoudSpeaker:aIsPlay];
     [self sessionHandleEnableOtherAudio:!aIsPlay];
    BOOL isHaveAudio = ((self.localUser.publishState == 1) || (self.localUser.publishState == 3));
    if (isHaveAudio) { [self sessionHandleEnableAudio:!aIsPlay];}
   
}
//Selecting audio inputs
-(void)selectingAudioInputs{
    //private var inputs = [AVAudioSessionPortDescription]()
    AVAudioSession *tSession = [AVAudioSession sharedInstance];

    //Built-in microphone-内置麦克风
    //Microphone on a wired headset-耳机上麦克风
    //Headphone or headset - 耳机
    //The speaker - 扬声器
    //Built-in speaker - 内置扬声器
   //InReceiver - 听筒
    NSMutableArray<AVAudioSessionPortDescription *> * inputs = [NSMutableArray arrayWithCapacity:10];
    
    NSArray<AVAudioSessionPortDescription *> *availableInputs=   tSession.availableInputs;
    for (AVAudioSessionPortDescription* input in availableInputs) {
        if (input.portType == AVAudioSessionPortBuiltInMic || input.portType == AVAudioSessionPortHeadsetMic) {
            [inputs addObject:input];
        }
    }
    [tSession setPreferredInput:[inputs firstObject]  error:nil];

}

#pragma mark 检测摄像头和麦克风
- (void)checkDevice {
    if (self.getMicrophoneFail == YES && self.getCameraFail == YES) {
        if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(noCameraAndNoMicrophone)]) {
            [(id<TKEduSessionDelegate>) _iSessionDelegate noCameraAndNoMicrophone];
        }
    } else {
        if (self.getMicrophoneFail == YES) {
            if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(noMicrophone)]) {
                [(id<TKEduSessionDelegate>) _iSessionDelegate noMicrophone];
            }
        }
        
        if (self.getCameraFail == YES) {
            if (_iSessionDelegate && [_iSessionDelegate respondsToSelector:@selector(noCamera)]) {
                [(id<TKEduSessionDelegate>) _iSessionDelegate noCamera];
            }
        }
    }
}

#pragma mark 获取摄像头失败
-(void)callCameroError{
    if (_iRoomDelegate && [_iRoomDelegate respondsToSelector:@selector(onCameraDidOpenError)]) {
        
        [(id<TKEduRoomDelegate>) _iRoomDelegate onCameraDidOpenError];
        
    }
}
#pragma mark 进入前后台

-(void)enterForeground:(NSNotification *)aNotification{
    TKLog(@"----sessionHandle2  %@",@(_iIsPlaying));

    if (_iCurrentMediaDocModel &&  _iIsPlaying && (self.localUser.role == UserType_Student)) {
       
    }
//    if (self.localUser.role == UserType_Student) {
//        NSString *tMsgID = [NSString stringWithFormat:@"%@_%@",sUserEnterBackGround,self.localUser.peerID];
//        [self sessionHandleDelMsg:sUserEnterBackGround ID:tMsgID To:sTellAllExpectSender Data:nil completion:nil];
//
//    }
    
}
-(void)enterBackground:(NSNotification *)aNotification{
     //TKLog(@"----sessionHandle");
 
     TKLog(@"----sessionHandle  %@",@(_iIsPlaying));
    if (_iCurrentMediaDocModel&&_iIsPlaying && (self.localUser.role == UserType_Student)) {
       
    }
//    if (self.localUser.role == UserType_Student) {
//        NSString *tMsgID = [NSString stringWithFormat:@"%@_%@",sUserEnterBackGround,self.localUser.peerID];
//        [self sessionHandlePubMsg:sUserEnterBackGround ID:tMsgID To:sTellAllExpectSender Data:nil Save:true AssociatedMsgID:sUserEnterBackGround AssociatedUserID:self.localUser.peerID completion:nil];
//    }
    
    
}
#pragma mark 用户自己打开关闭音视频
- (void)disableMyVideo:(BOOL)disable {
    [_roomMgr disableMyVideo:disable];
}

- (void)disableMyAudio:(BOOL)disable {
    [_roomMgr disableMyAudio:disable];
}
#pragma mark media

-(void)sessionHandlePublishMedia:(NSString *)fileurl hasVideo:(BOOL)hasVideo fileid:(NSString *)fileid  filename:(NSString *)filename toID:(NSString*)toID block:(void (^)(NSError *))block{
    if (!toID || [toID isEqualToString:@""]) {
         [_roomMgr publishMedia:fileurl hasVideo:hasVideo fileid:fileid filename:filename block:block];
    }else{
         [_roomMgr publishMedia:fileurl hasVideo:hasVideo fileid:fileid filename:filename toID:toID block:block];
    }
   
  
}

-(void)sessionHandleUnpublishMedia:(void (^)(NSError *))block{
    [_roomMgr unpublishMedia:block];
}
- (void)sessionHandlePlayMedia:(NSString*)fileId completion:(void (^)(NSError *error, NSObject *view))block{
    [_roomMgr playMedia:fileId completion:block];
}

-(void)sessionHandleMediaPause:(BOOL)pause{
    [_roomMgr mediaPause:pause];
}
-(void)sessionHandleMediaSeektoPos:(NSTimeInterval)pos{
    [_roomMgr mediaSeektoPos:pos];
}
-(void)sessionHandleMediaVolum:(CGFloat)volum{
    [_roomMgr mediaVolum:volum];
    
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

#pragma mark screen

-(void)sessionHandlePlayScreen:(NSString *)peerId completion:(void (^)(NSError *error, NSObject *view))block {
    [_roomMgr playScreen:peerId completion:block];
}

-(void)sessionHandleUnPlayScreen:(NSString *)peerId completion:(void (^)(NSError *error))block {
    [_roomMgr unPlayScreen:peerId completion:block];
}

#pragma mark - 回放
- (void)playback {
    [_roomMgr playback];
}

- (void)pausePlayback {
    [_roomMgr pausePlayback];
}

- (void)seekPlayback:(NSTimeInterval)positionTime {
    [_roomMgr seekPlayback:positionTime];
}
#pragma mark - 设置权限
// 从1 开始 36:支持h5课件  37:助教是否开启音视频  38:画笔权限  39:允许操作ppt翻页
-(void)configureDrawAndPageWithControl:(NSString *)aChairmancontrol{
    
    NSRange tAssitOpenVInitRange = NSMakeRange(36, 1);
    NSRange tDrawRange           = NSMakeRange(37, 1);
    NSRange tPageRange           = NSMakeRange(38, 1);
    NSString *tAssistStr  = [aChairmancontrol substringWithRange:tAssitOpenVInitRange];
    
    NSString *tDrawStr     = [aChairmancontrol substringWithRange:tDrawRange];
    NSString *tPageStr     = [aChairmancontrol substringWithRange:tPageRange];
    self.iIsCanDrawInit    = [tDrawStr integerValue];
    self.iIsCanPageInit    = [tPageStr integerValue];
    self.iIsAssitOpenVInit = [tAssistStr integerValue];
    
}
//sTellAll
- (void)configureDraw:(BOOL)isDraw isSend:(BOOL)isSend to:(NSString *)to peerID:(NSString*)peerID{
    BOOL isMe = [peerID isEqualToString:self.localUser.peerID];
    self.iIsCanDraw = isMe ?isDraw:self.iIsCanDraw;
    [self.iBoardHandle setDrawable:self.iIsCanDraw];
    if (isSend) {
        [self sessionHandleChangeUserProperty: peerID TellWhom:to Key:sCandraw Value:@((bool)(isDraw)) completion:nil];
    }
    
}
- (void)configurePage:(BOOL)isPage isSend:(BOOL)isSend to:(NSString *)to peerID:(NSString*)peerID{
    
    BOOL isMe = [peerID isEqualToString:self.localUser.peerID];
    self.iIsCanPage = isMe ?isPage:self.iIsCanPage;
    [self.iBoardHandle setPagePermission: self.iIsCanPage];
    if (isSend) {}
    
}
-(void)dealloc{
    TKLog(@"----sessionHandle");
}

@end
