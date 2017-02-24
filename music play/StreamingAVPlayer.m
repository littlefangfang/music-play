//
//  StreamingAVPlayer.m
//  audio stream
//
//  Created by yu on 2016/12/14.
//  Copyright © 2016年 xinyue-0. All rights reserved.
//

#import "StreamingAVPlayer.h"

@interface StreamingAVPlayer () <NSURLSessionDataDelegate, NSURLSessionTaskDelegate, AVAssetResourceLoaderDelegate, AVAudioPlayerDelegate> {
    
}

@end

@implementation StreamingAVPlayer {
    BOOL setDataSourceOK, shouldPlay;
    
    NSString *localAudioFolderPath;
    
    NSArray *audioPaths, *audioNames;
    
    NSTimer *timer;
    
    // player and data holders
    NSString *name; // name of a instance of this classes
    AVPlayer *player;
    NSHTTPURLResponse *urlResponse;
    NSMutableData *audioData;
    NSMutableArray *pendingRequests;
    
    // session and task
    NSURLSessionDataTask *sessionDataTask;
    NSURLSession *session;
    
    // current audio info
    NSInteger currentPlayIndex;
    float currentAudioDataTotalLength;
    NSString *currentAudioOriginScheme;
    float currentAudioDuration;
    
    // 锁屏时播放条的进度速率，暂停时需要设置为接近0的数
    float playbackRate;
}
static StreamingAVPlayer *_instance;
@synthesize shouldPlay = _shouldPlay;
@synthesize currentPlayIndex = _currentPlayIndex;

#pragma mark - Life Cycle


// init
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

+ (instancetype)shared{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(_instance == nil)
            _instance = [[StreamingAVPlayer alloc] init];
    });
    return _instance;
}


/**
 初始化本类的一个实例，并给这个实例起一个名字。实例的名字主要用来区分委托方法是被哪个实例调用的（当一个控制器中有两个或以上的本类实例时）。

 @param nameString 播放器的名字
 @return self的实例
 */
- (instancetype)initWithName:(NSString *)nameString
{
    self = [super init];
    if (self) {
        name = nameString;
        [self setup];
    }
    return self;
}

- (void)setup
{
    currentPlayIndex = 0;    
}

// destroy

#pragma mark - General Methods

/**
 设置或修改播放器的名字，若播放器在初始化时没有名字。则可用本方法对播放器设置名字。

 @param nameString 播放器名称
 */
- (void)setPlayerName:(NSString *)nameString
{
    name = nameString;
}

#pragma mark - Set Audio Source (Methods)


/**
 设置音频数据，需要传入离线保存音频的本地文件夹地址、音频的url地址（数组）、音频的显示名（数组）、当前需要从第个音频开始播放。

 @param path 音频在本地被保存到的文件夹的路径
 @param auds 音频在服务器上的url路径
 @param audNames 音频的显示名，显示名的数量需要与auds的数量相等
 @param idx 从第几个音频开始播放
 */
- (void)setAudioFolderPath:(NSString *)path audioPaths:(NSArray *)auds audioNames:(NSArray *)audNames startIndex:(NSInteger)idx
{
    if (!path) {
        setDataSourceOK = NO;
        shouldPlay = NO;
        return;
    }
    
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
        NSError *err;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&err];
        if (err) {
            NSLog(@"create fold err: %@",err);
            shouldPlay = NO;
            return;
        }
    }
    
    if (!auds || auds.count == 0 || auds.count != audNames.count || idx >= auds.count) {
        setDataSourceOK = NO;
        shouldPlay = NO;
        return;
    }
    
    localAudioFolderPath = path;
    audioPaths = auds;
    audioNames = audNames;
    currentPlayIndex = idx;
    
    setDataSourceOK = YES;
}

#pragma mark - Console (Methods)


/**
 播放音频或从暂停中恢复音频播放
 
 程序先通过 currentPlayIndex 取得当前需要播放的音频的url地址。让后将url地址中的最后一个部分（即文件名）取到。并在本地音频文件夹中寻找完全符合该文件名的文件。若能找到，则直接播放本地文件；若无法找到，则从url进行流播放。当流下载完后，将下载的文件存入本地的音频文件夹中。
 */
- (void)play
{
    if (!timer) {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timeTicking:) userInfo:nil repeats:YES];
        [timer fire];
    }
    
    NSString *filePath = [localAudioFolderPath stringByAppendingPathComponent:[[audioPaths objectAtIndex:currentPlayIndex] lastPathComponent]];
    filePath = [filePath stringByReplacingOccurrencesOfString:@"?fromtag=46" withString:@""];
    NSFileManager *fmr = [NSFileManager defaultManager];
    
    if ([fmr fileExistsAtPath:filePath]) {
        if (player == nil) {
            AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:filePath]];
            player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            [self addObserverToPlayerItem:playerItem];
            [self updateAudioDownload:1];
        }
        
    }else {
        NSURL *audURL = [NSURL URLWithString:[audioPaths objectAtIndex:currentPlayIndex]];
        currentAudioOriginScheme = audURL.scheme;
        shouldPlay = YES;
        
        if (player == nil) {
            AVPlayerItem *playerItem = [self getPlayerItemFromhURL:audURL];
            player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            [self addObserverToPlayerItem:playerItem];
            
        }
    }
    
    // update player status
    [self updatePlayerStatus:StreamingAVPlayer_Status_Playing];
    
    // update audio name
    [self updateAudioName];
    
    playbackRate = 1.0f;
    
    [player play];
    player.rate = 1.0;
}

/**
 暂停播放当前音频
 */
- (void)pause
{
    shouldPlay = NO;
    
    playbackRate = 0.00001f;
    [player pause];
    [self updatePlayerStatus:StreamingAVPlayer_Status_Pause];
}


/**
 为当前播放的音频设置一个开始播放时间

 @param seconds 设置开始播放的时间，单位：秒
 */
- (void)setProgressInTermsOfSeconds:(float)seconds
{
    //当视频状态为AVPlayerStatusReadyToPlay时才处理
    if (player.status == AVPlayerStatusReadyToPlay) {
        NSTimeInterval ti = seconds;
        CMTime seekTime = CMTimeMake(ti, 1);
        
        __weak StreamingAVPlayer *weakSelf = self;
        [player seekToTime:seekTime completionHandler:^(BOOL finished) {
            [weakSelf updateAudioPosition:seconds];
        }];
    }
}


/**
 为当前播放的音频设置一个开始播放的百分比

 @param percent 开始播放的百分比（范围：0到1之间的小数）
 */
- (void)setProgressInTermsOfPercentage:(float)percent
{
    float ti = currentAudioDuration * percent;
    [self setProgressInTermsOfSeconds:ti];
}

/**
 停止播放当前音频
 */
- (void)stop
{
    shouldPlay = NO;
    playbackRate = 0.00001f;
    
    [sessionDataTask cancel];
    sessionDataTask = nil;
    
    [session invalidateAndCancel];
    session = nil;
    
    [player pause];
    
    [self updateAudioPosition:0];
    [self updateAudioDownload:0];
    [self updatePlayerStatus:StreamingAVPlayer_Status_Stop];
    
    [self removeObserverFromPlayerItem:player.currentItem];
    player = nil;
    
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
}


/**
 播放上一个
 */
- (void)previous
{
    if (currentPlayIndex > 0) {
        [self stop];
        currentPlayIndex -= 1;
        [self play];
    }
}


/**
 播放下一个
 */
- (void)next
{
    if (currentPlayIndex < audioPaths.count - 1) {
        [self stop];
        currentPlayIndex += 1;
        [self play];
    }
}

#pragma mark - Timer update UI

/**
 更新播放器名，会调用代理方法 streamAVPlayer:updateAudioName:
 */
- (void)updateAudioName
{
    NSString *audName = [audioNames objectAtIndex:currentPlayIndex];
    if (_delegate && [_delegate respondsToSelector:@selector(streamAVPlayer:updateAudioName:)]) {
        [_delegate streamAVPlayer:name updateAudioName:audName];
    }
}


/**
 更新音频总时长

 @param length 音频总长度，会调用代理方法streamAVPlayer:updateAudioDuration:
 */
- (void)updateAudioDuration:(float)length
{
    currentAudioDuration = length;
    if (_delegate && [_delegate respondsToSelector:@selector(streamAVPlayer:updateAudioDuration:)]) {
        [_delegate streamAVPlayer:name updateAudioDuration:currentAudioDuration];
    }
}


/**
 更新下载的进度，会调用代理方法 streamAVPlayer:updateAudioDownloadDataLength:andDownloadPercentage:

 @param currentDataLength 已下载的文件长度
 */
- (void)updateAudioDownload:(float)currentDataLength
{
    if (_delegate && [_delegate respondsToSelector:@selector(streamAVPlayer:updateAudioDownloadDataLength:andDownloadPercentage:)]) {
        float downloadPercent = currentDataLength / currentAudioDataTotalLength;
        [_delegate streamAVPlayer:name updateAudioDownloadDataLength:currentDataLength andDownloadPercentage:downloadPercent];
    }
}


/**
 更新播放进度，会调用代理方法 streamAVPlayer:updateAudioPositionSeconds:andPositionPercentage:

 @param seconds 当前播放的时间
 */
- (void)updateAudioPosition:(float)seconds
{
    if (_delegate && [_delegate respondsToSelector:@selector(streamAVPlayer:updateAudioPositionSeconds:andPositionPercentage:)]) {
        float progressPercent = seconds / currentAudioDuration;
        [_delegate streamAVPlayer:name updateAudioPositionSeconds:seconds andPositionPercentage:progressPercent];
    }
}


/**
 更新播放器状态，会调用代理方法 streamAVPlayer:updatePlayerStatus:

 @param status 播放器状态 playing pause stop
 */
- (void)updatePlayerStatus:(NSString *)status
{
    if (_delegate && [_delegate respondsToSelector:@selector(streamAVPlayer:updatePlayerStatus:)]) {
        [_delegate streamAVPlayer:name updatePlayerStatus:status];
    }
}


/**
 当全部播放完成时调用，会调用代理方法 streamAVPlayerFinishPlayingAllAudio:
 */
- (void)finishPlayingAllAudio
{
    if (_delegate && [_delegate respondsToSelector:@selector(streamAVPlayerFinishPlayingAllAudio:)]) {
        [_delegate streamAVPlayerFinishPlayingAllAudio:name];
    }
}

#pragma mark - AVURLAsset resource loading
- (void)processPendingRequests
{
    NSMutableArray *requestsCompleted = [NSMutableArray array];
    
    for (AVAssetResourceLoadingRequest *loadingRequest in pendingRequests)
    {
        [self fillInContentInformation:loadingRequest.contentInformationRequest];
        
        BOOL didRespondCompletely = [self respondWithDataForRequest:loadingRequest.dataRequest];
        
        if (didRespondCompletely)
        {
            [requestsCompleted addObject:loadingRequest];
            
            [loadingRequest finishLoading];
        }
    }
    [pendingRequests removeObjectsInArray:requestsCompleted];
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    if (contentInformationRequest == nil || urlResponse == nil)
    {
        return;
    }
    
    NSString *mimeType = [urlResponse MIMEType];
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = [urlResponse expectedContentLength];
}

- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest
{
    long long startOffset = dataRequest.requestedOffset;
    if (dataRequest.currentOffset != 0)
    {
        startOffset = dataRequest.currentOffset;
    }
    
    // Don't have any data at all for this request
    if (audioData.length < startOffset)
    {
        return NO;
    }
    
    // This is the total data we have from startOffset to whatever has been downloaded so far
    NSUInteger unreadBytes = audioData.length - (NSUInteger)startOffset;
    
    // Respond with whatever is available if we can't satisfy the request fully yet
    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
    
    [dataRequest respondWithData:[audioData subdataWithRange:NSMakeRange((NSUInteger)startOffset, numberOfBytesToRespondWith)]];
    
    long long endOffset = startOffset + dataRequest.requestedLength;
    BOOL didRespondFully = audioData.length >= endOffset;
    return didRespondFully;
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    if (session == nil)
    {
        NSURL *interceptedURL = [loadingRequest.request URL];
        NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:interceptedURL resolvingAgainstBaseURL:NO];
        actualURLComponents.scheme = currentAudioOriginScheme;
        
        NSURL *u = [actualURLComponents URL];
        NSURLRequest *request = [NSURLRequest requestWithURL:u];
        
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        session =  [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
        sessionDataTask = [session dataTaskWithRequest:request];
        [sessionDataTask resume];
    }

    [pendingRequests addObject:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [pendingRequests removeObject:loadingRequest];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    completionHandler(NSURLSessionResponseAllow);
    
    currentAudioDataTotalLength = response.expectedContentLength;
    
    audioData = [NSMutableData data];
    urlResponse = (NSHTTPURLResponse *)response;
    
    [self processPendingRequests];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [audioData appendData:data];
    
    [self updateAudioDownload:audioData.length];
    
    [self processPendingRequests];
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (!error) {
        [self processPendingRequests];
        NSString *cachedFilePath = [localAudioFolderPath stringByAppendingPathComponent:[[audioPaths objectAtIndex:currentPlayIndex] lastPathComponent]];
        cachedFilePath = [cachedFilePath stringByReplacingOccurrencesOfString:@"?fromtag=46" withString:@""];
        [audioData writeToFile:cachedFilePath atomically:YES];
    }else{
        NSLog(@"download not finished with error : %@", error);
    }
    
}

// for https:// protocol check
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    // Get remote certificate
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
    
    // Set SSL policies for domain name check
    NSMutableArray *policies = [NSMutableArray array];
    [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)challenge.protectionSpace.host)];
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
    
    // Evaluate server certificate
    SecTrustResultType result;
    SecTrustEvaluate(serverTrust, &result);
//    BOOL certificateIsValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
    
    // Get local and remote cert data
    NSData *remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));
    NSString *pathToCert = [[NSBundle mainBundle]pathForResource:@"ch103.com" ofType:@"cer"];
    NSData *localCertificate = [NSData dataWithContentsOfFile:pathToCert];
    
// The pinnning check
//    if ([remoteCertificateData isEqualToData:localCertificate] && certificateIsValid) {
//        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
//        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
//    } else {
//        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, NULL);
//    }
    
    if ([remoteCertificateData isEqualToData:localCertificate]) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, NULL);
    }
}

#pragma Key Value Observation

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
//        NSLog(@"%f",[self availableDurationWithplayerItem:player.currentItem]);
    }
    
    if (player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        float audioDurationSeconds = CMTimeGetSeconds(player.currentItem.duration);
        [self updateAudioDuration:audioDurationSeconds];
        
        if (shouldPlay) {
            [player play];
            player.rate = 1.0;
        }
    }
}

#pragma mark - Helpers
/**
 播放当前数组中选中的音频,点击上一首或者下一首之后调用
 */
- (void)playCurrent
{
    [sessionDataTask cancel];
    sessionDataTask = nil;
    
    [session invalidateAndCancel];
    session = nil;
    
    [self pause];
}

- (AVPlayerItem *)getPlayerItemFromhURL:(NSURL *)url
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[self audioURL:url withCustomScheme:@"streaming"] options:nil];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    
    pendingRequests = [NSMutableArray array];
    return [AVPlayerItem playerItemWithAsset:asset];
}

- (NSURL *)audioURL:(NSURL *)audioURL withCustomScheme:(NSString *)scheme
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:audioURL resolvingAgainstBaseURL:NO];
    components.scheme = scheme;
    
    return [components URL];
}

/**
 *  给AVPlayerItem添加监控
 *
 *  @param playerItem AVPlayerItem对象
 */
-(void)addObserverToPlayerItem:(AVPlayerItem *)playerItem
{
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //播放完成调用
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
}

/**
 计算可播放的时间
 
 @param playerItem 需要计算的playItem
 @return 可播放的时间
 */
- (NSTimeInterval)availableDurationWithplayerItem:(AVPlayerItem *)playerItem
{
    NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    NSTimeInterval startSeconds = CMTimeGetSeconds(timeRange.start);
    NSTimeInterval durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

/**
 *  给AVPlayerItem移除监控
 *
 *  @param playerItem AVPlayerItem对象
 */
-(void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem
{
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 设置锁屏信息
 */
- (void)setPlayingInfo
{
    Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    
    if (playingInfoCenter) {
        
        //数据信息
        NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
        
        //图片
//        MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"123.jpg"]];
        UIImage *img = [UIImage imageNamed:@"123.jpg"];
        MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithBoundsSize:img.size requestHandler:^UIImage * _Nonnull(CGSize size) {
            return img;
        }];
        [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
        
        //当前播放时间
        [songInfo setObject:[NSNumber numberWithDouble:CMTimeGetSeconds(player.currentItem.currentTime)] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        
        //速率
        [songInfo setObject:[NSNumber numberWithFloat:playbackRate] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        
        //总时长
        [songInfo setObject:[NSNumber numberWithDouble:CMTimeGetSeconds(player.currentItem.duration)] forKey:MPMediaItemPropertyPlaybackDuration];
        
        //设置标题
//        [songInfo setObject:[audioNames objectAtIndex:currentPlayIndex] forKey:MPMediaItemPropertyTitle];
        
        //设置副标题
//        [songInfo setObject:@"古兰经 - 副标题" forKey:MPMediaItemPropertyArtist];
        
        //设置音频数据信息
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
    }
}

- (void)timeTicking:(NSTimer *)t
{
    [self setPlayingInfo]; //后台播放显示信息设置
    float currentSeconds = CMTimeGetSeconds([player currentTime]);
    [self updateAudioPosition:currentSeconds >= 0 ? currentSeconds : 0.0f];
}

/**
 播放完成调用
 
 @param notice 当前的通知
 */
- (void)playbackFinished:(NSNotification *)notice
{
    NSLog(@"播放完成");
    if (currentPlayIndex >= audioPaths.count - 1) {
        [self finishPlayingAllAudio];
        
    }else {
        [self next];
    }
}

@end

