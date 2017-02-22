//
//  StreamingAVPlayer.h
//  audio stream
//
//  Created by yu on 2016/12/14.
//  Copyright © 2016年 xinyue-0. All rights reserved.
//

#define StreamingAVPlayer_Status_Playing @"playing"
#define StreamingAVPlayer_Status_Pause @"pause"
#define StreamingAVPlayer_Status_Stop @"stop"

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol StreamingAVPlayerDelegate <NSObject>

@optional

/**
 通知控制器更新音频的名字

 @param playerName 播放器的名字。当控制器中有多个播放器时，用来区别播放器
 @param audioName 音频名字。当前播放的音频的显示名字
 */
- (void)streamAVPlayer:(NSString *)playerName updateAudioName:(NSString *)audioName;


/**
 通知控制器更新音频的播放时长（单位：秒）

 @param playerName 播放器的名字。当控制器中有多个播放器时，用来区别播放器
 @param seconds 当前所播放的音频的时长
 */
- (void)streamAVPlayer:(NSString *)playerName updateAudioDuration:(float)seconds;


/**
 通知控制器更新音频下载进度

 @param playerName 播放器的名字。当控制器中有多个播放器时，用来区别播放器
 @param length 当前音频已经下载的字节数
 @param percent 当前音频已经下载的百分比
 */
- (void)streamAVPlayer:(NSString *)playerName updateAudioDownloadDataLength:(NSInteger)length andDownloadPercentage:(float)percent;


/**
 通知控制器更新当前音频的播放进度

 @param playerName 播放器的名字。当控制器中有多个播放器时，用来区别播放器
 @param seconds 当前音频播放到了第几秒
 @param percent 当前音频播放的百分比
 */
- (void)streamAVPlayer:(NSString *)playerName updateAudioPositionSeconds:(float)seconds andPositionPercentage:(float)percent;


/**
 通知控制器更新播放状态。目前播放状态有三种：StreamingAVPlayer_Status_Playing; StreamingAVPlayer_Status_Pause; StreamingAVPlayer_Status_Stop

 @param playerName 播放器的名字。当控制器中有多个播放器时，用来区别播放器
 @param status 播放器当前的状态
 */
- (void)streamAVPlayer:(NSString *)playerName updatePlayerStatus:(NSString *)status;


/**
 播放器数组中的全部音频已经被播放完毕

 @param playerName 播放器的名字。当控制器中有多个播放器时，用来区别播放器
 */
- (void)streamAVPlayerFinishPlayingAllAudio:(NSString *)playerName;

@end




@interface StreamingAVPlayer : NSObject
/**
 StreamingAVPlayerDelegate委托的实例。
 */
@property (nonatomic, weak) id <StreamingAVPlayerDelegate> delegate;

/**
 在播放音频前需要查看该值是否为 YES。如果是则可以播放，如果不是，则不能播放
 */
@property (nonatomic, assign) BOOL shouldPlay;

/**
 当前播放的音频是数组中的第几个
 */
@property (nonatomic, assign) NSInteger currentPlayIndex;

#pragma mark - Life Cycle
+ (instancetype)shared;
//- (instancetype)initWithName:(NSString *)nameString;

#pragma mark - General Methods
- (void)setPlayerName:(NSString *)nameString;

#pragma mark - Set Audio Source (Methods)
- (void)setAudioFolderPath:(NSString *)path audioPaths:(NSArray *)auds audioNames:(NSArray *)audNames startIndex:(NSInteger)idx;

#pragma mark - Console (Methods)
- (void)play;
- (void)pause;
- (void)setProgressInTermsOfSeconds:(float)seconds;
- (void)setProgressInTermsOfPercentage:(float)percent;
- (void)stop;
- (void)previous;
- (void)next;

@end
