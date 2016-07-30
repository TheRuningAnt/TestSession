//
//  ViewController.m
//  TestSession
//
//  Created by 赵广亮 on 16/7/28.
//  Copyright © 2016年 zhaoguangliang. All rights reserved.
//

#import "ViewController.h"
#import "LLProgressView.h"
#import <AVFoundation/AVFoundation.h>

#define k_DownloadURLStr @"http://oarbi0614.bkt.clouddn.com/%E5%86%B0%E6%B2%B3%E4%B8%96%E7%BA%AA.mp4"
#define k_ScreenWidth [UIScreen mainScreen].bounds.size.width
#define k_ScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<NSURLSessionDownloadDelegate>

@property (nonatomic,strong) NSURLSession *session;
@property (nonatomic,strong) NSURLSessionDownloadTask* downloadTask;
@property (nonatomic,strong) NSData *downloadData;
@property (nonatomic,strong) LLProgressView *progressView;
@property (nonatomic,strong) AVPlayer *avPlayer;
@property (nonatomic,assign) BOOL downloading;
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,strong) AVPlayerLayer *playerLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setUp];
}

//初始化应用
-(void)setUp{
    //设置背景图
    UIImageView *imageV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Back_Image"]];
    imageV.layer.frame = [UIScreen mainScreen].bounds;
    self.view.layer.contents = imageV.layer.contents;
    
    [self.view addSubview:self.progressView];
    //添加屏幕旋转的通知
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenTransform:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

//开始下载
- (IBAction)startDownload:(id)sender {
    //下载之前检查下是否已经下载该视频
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSURL *urlOfMV = [NSURL fileURLWithPath:paths[0]];
    urlOfMV = [urlOfMV URLByAppendingPathComponent:@"冰河世纪.mov"];
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if (self.downloading){
        [self tipViewWithMessage:@"正在下载"];
    }else if(self.avPlayer){
        [self tipViewWithMessage:@"正在播放"];
    }else if([manager fileExistsAtPath:urlOfMV.path]) {
        [self addMVPlayerWithFileUrl:urlOfMV];
        [self.avPlayer play];
    }else if(self.downloadData){
        [self resumeDownload:nil];
    }else{
        [self.downloadTask resume];
        self.downloading = true;
    }
}

//暂停下载
- (IBAction)pauseDownload:(id)sender {
    if (!self.downloading) {
        [self tipViewWithMessage:@"暂无下载任务"];
        return;
    }
    __weak typeof (self)weakSelf = self;
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        weakSelf.downloadData = resumeData;
    }];
    self.downloading = false;
}

//恢复下载
- (IBAction)resumeDownload:(id)sender {
    if (self.downloading) {
        [self tipViewWithMessage:@"正在下载"];
        return;
    }else if(self.avPlayer){
        [self tipViewWithMessage:@"正在播放"];
        return;
    }
    if (self.downloadData) {
        self.downloadTask = [self.session downloadTaskWithResumeData:self.downloadData];
        [self.downloadTask resume];
        self.downloading = true;
        return;
    }
    [self tipViewWithMessage:@"当前没有正在下载的任务"];
    return;
}

//播放MV
- (IBAction)playMV:(id)sender {
    if (self.avPlayer) {
        [self.avPlayer play];
        return;
    }
    [self tipViewWithMessage:@"资源未下载完成,暂无播放器"];
    return;
}

//暂停MV
- (IBAction)pauseMV:(id)sender {
    if (self.avPlayer) {
        [self.avPlayer pause];
        return;
    }
    [self tipViewWithMessage:@"资源未下载完成,暂无播放器"];
    return;
}

//重置应用
- (IBAction)resetApp:(id)sender {
    if (self.progressView) {
        [self.session invalidateAndCancel];
        [self.progressView removeFromSuperview];
        self.downloading = false;
        self.progressView = nil;
    }
    [self.playerLayer removeFromSuperlayer];
    [self.avPlayer pause];
    [self.view addSubview:self.progressView];
    
    //移除缓存的资源
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSURL *urlOfMV = [NSURL fileURLWithPath:paths[0]];
    urlOfMV = [urlOfMV URLByAppendingPathComponent:@"冰河世纪.mov"];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:urlOfMV.path]) {
        [manager removeItemAtPath:urlOfMV.path error:nil];
    }
    
    self.avPlayer = nil;
    self.session = nil;
    self.downloadTask = nil;
    self.downloadData = nil;
    self.downloading = false;
}

//屏幕旋转时调用的方法
-(void)screenTransform:(NSNotification*)notification{
    UIDevice *device = notification.object;
    if (device.orientation == UIDeviceOrientationPortrait) {
        self.playerLayer.frame = CGRectMake(0, 0, k_ScreenWidth, 400);
    }else{
        self.playerLayer.frame = CGRectMake(0, 0, k_ScreenWidth, k_ScreenHeight);
    }
}

#pragma mark:懒加载变量

-(NSURLSession *)session{
    if (!_session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.discretionary = YES;  //自由决定选择哪种网络状态进行下载数据
        _session = [NSURLSession sessionWithConfiguration:configuration
                                                              delegate:self
                                                        delegateQueue:nil];
    }
    return _session;
}

-(NSURLSessionDownloadTask *)downloadTask{
    if (!_downloadTask) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:k_DownloadURLStr]];
        _downloadTask = [self.session downloadTaskWithRequest:request];
    }
    return _downloadTask;
}

-(NSData *)downloadData{
    if (!_downloadData) {
        _downloadData = [NSData data];
    }
    return _downloadData;
}

-(LLProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[LLProgressView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)
                                                   trackColor:[UIColor blackColor]
                                                progressColor:[UIColor orangeColor]
                                                    lineWidth:20
                                                progressValue:0.0
                                                     fontSize:24
                                                     autoLoad:NO];
        _progressView.center = CGPointMake(k_ScreenWidth/2, 240);
    }
    return _progressView;
}

#pragma mark:调用方法
//添加视频播放器
-(void)addMVPlayerWithFileUrl:(NSURL*)fileUrl{
    AVURLAsset *asset = [AVURLAsset assetWithURL:fileUrl];
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:asset];
    self.avPlayer = [AVPlayer playerWithPlayerItem:item];
    self.avPlayer.volume = 1.0f;
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    self.playerLayer.frame = CGRectMake(0, 0, k_ScreenWidth, 400);
    self.playerLayer.backgroundColor = [UIColor clearColor].CGColor;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
   self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playerStatude) userInfo:nil repeats:YES];
    
    if (self.progressView.superview) {
        [self.progressView removeFromSuperview];
    }
    [self.view.layer addSublayer:self.playerLayer];
}

-(void)tipViewWithMessage:(NSString*)message{
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
    UIAlertController *alertControl = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertControl addAction:action];
    [self presentViewController:alertControl animated:YES completion:nil];
}

#pragma mark:NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    if(self.downloading){
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:1.0 * totalBytesWritten / totalBytesExpectedToWrite];
    });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    
    NSURL *urlOfSave = [NSURL fileURLWithPath:paths[0]];
    urlOfSave = [urlOfSave URLByAppendingPathComponent:@"冰河世纪.mov"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:urlOfSave.path]) {
        //如果文件夹下有同名文件  则将其删除
        [fileManager removeItemAtURL:urlOfSave error:nil];
    }
    //将下载好的文件复制到存储的文件夹下
    [fileManager copyItemAtURL:location toURL:urlOfSave error:nil];
    
    [self.session invalidateAndCancel];
    self.session = nil;
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.downloading = false;
        //将视频播放器添加到页面上并且开始播放
        [weakSelf addMVPlayerWithFileUrl:urlOfSave];
        [weakSelf playMV:nil];
    });
}

-(void)playerStatude{
    if (self.avPlayer.currentItem.duration.value == self.avPlayer.currentItem.currentTime.value) {
        [self tipViewWithMessage:@"播放完了哦"];
        [self.timer invalidate];
        self.avPlayer = nil;
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{
    NSLog(@"%@",error);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
