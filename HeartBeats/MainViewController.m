//
//  Copyright (c) 2013 Christian Roman. All rights reserved.
//

#import "MainViewController.h"
#import "HSVUtils.h"
#import "NetworkService.h"

static float timeInterval = 10.f;

@interface MainViewController () {
  CALayer* imageLayer;
}

@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *switchButton;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) NSMutableArray *points;
@property (nonatomic, strong) NSMutableArray *beats;
@property (nonatomic, strong) NSMutableArray *captureTimes;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSTimer *secondsTimer;

@property (nonatomic, assign) BOOL isRecording;

@end

@implementation MainViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setupImageLayer];
  [self setupTimeLabel];
  [self setupSwitch];
  [self startAVCapture];
}

- (void)setupImageLayer {
  imageLayer = [CALayer layer];
  imageLayer.frame = self.view.layer.bounds;
  imageLayer.contentsGravity = kCAGravityResizeAspectFill;
  [self.view.layer addSublayer:imageLayer];
}

- (void)setupTimeLabel {
  UILabel *timeLabel = [UILabel new];
  timeLabel.font = [UIFont fontWithName:@"Times New Roman" size:35.f];
  timeLabel.text = @"00:00:00";
  timeLabel.textAlignment = NSTextAlignmentCenter;
  timeLabel.textColor = [UIColor blackColor];
  timeLabel.backgroundColor = [UIColor whiteColor];
  timeLabel.layer.masksToBounds = YES;
  timeLabel.layer.borderWidth = 2.f;
  timeLabel.layer.borderColor = [UIColor blackColor].CGColor;
  timeLabel.layer.cornerRadius = 4.f;
  timeLabel.frame = CGRectMake(0.f, 100.f, 200.f, 80.f);
  timeLabel.center = CGPointMake(self.view.center.x, timeLabel.frame.origin.y);
  timeLabel.adjustsFontSizeToFitWidth = YES;
  
  [self.view addSubview:timeLabel];
  self.timeLabel = timeLabel;
}

- (void)updateTimePerMs {
  NSArray *timeComponents = [self.timeLabel.text componentsSeparatedByString:@":"];
  NSInteger m = [[timeComponents objectAtIndex:0] integerValue];
  NSInteger s = [[timeComponents objectAtIndex:1] integerValue];
  NSInteger ms = [[timeComponents objectAtIndex:2] integerValue];
  ms++;
  if (ms >= 100) {
    ms = 0;
    s++;
    if (s >= 60) {
      s = 0;
      m++;
      if (m >= 60) {
        m = 0;
      }
    }
  }
  self.timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)m, (long)s, (long)ms];
}

- (void)setupSwitch {
  UIButton *switchButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 100, 40)];
  switchButton.backgroundColor = [UIColor whiteColor];
  [switchButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  switchButton.layer.cornerRadius = 4.f;
  switchButton.layer.masksToBounds = YES;
  switchButton.layer.borderWidth = 2.f;
  switchButton.layer.borderColor = [UIColor blackColor].CGColor;
  [switchButton setTitle:@"开始" forState:UIControlStateNormal];
  switchButton.center = CGPointMake(self.view.center.x, self.view.frame.size.height - 100);
  [switchButton addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventTouchUpInside];
  
  [self.view addSubview:switchButton];
  self.switchButton = switchButton;
}

- (void)switchAction:(UIButton *)sender {
  if (self.isRecording) {
    self.isRecording = NO;
    NSLog(@"%@", self.beats);
    _beats = nil;
    _captureTimes = nil;
    [self.timer invalidate];
    [self.secondsTimer invalidate];
    self.timer = nil;
    self.secondsTimer = nil;
    [self.switchButton setTitle:@"开始" forState:UIControlStateNormal];
  } else {
    self.timeLabel.text = @"00:00:00";
    self.isRecording = YES;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(sendData) userInfo:nil repeats:YES];
    self.secondsTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateTimePerMs) userInfo:nil repeats:YES];
    [self.switchButton setTitle:@"停止" forState:UIControlStateNormal];
  }
}

- (void)sendData {
  NSDictionary *HSVData = @{
                            @"time": [self currentTime],
                            @"user": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                            @"time_interval": [NSNumber numberWithFloat:timeInterval],
                            @"sample_rate": [self sampleRate],
                            @"label": @"none",
                            @"origin_data": [self reverseArray:[self.beats copy]],
                            @"origin_time": [self reverseArray:[self.captureTimes copy]]
                            };
  NetworkService *networkService = [NetworkService sharedService];
  [networkService post:@"/data" parameters:HSVData success:^(NSDictionary *response) {
    [self updateHeartRate: response[@"heart_rate"]];
    [self handleEmotionChange: response[@"emotion_changed"]];
  } failure:^(NSError *error) {
    [self showErrorAlert:error];
  }];
}

- (NSArray *)reverseArray:(NSArray *)array {
  NSMutableArray *array2 = [NSMutableArray arrayWithCapacity:[array count]];
  NSEnumerator *enumerator = [array reverseObjectEnumerator];
  for (id element in enumerator) {
    [array2 addObject:element];
  }
  return array2;
}

- (void)updateHeartRate:(NSString *)heartRate {
  
}

- (void)handleEmotionChange:(NSInteger)emotionChanged {
  
}

- (NSString *)currentTime {
  NSDate *date = [NSDate date];
  NSDateFormatter *formatter = [NSDateFormatter new];
  [formatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
  return [formatter stringFromDate:date];
}

- (NSNumber *)sampleRate {
  return [NSNumber numberWithFloat:self.beats.count / timeInterval];
}

- (void)viewWillDisappear:(BOOL)animated {
  [self stopAVCapture];
}

- (void)startAVCapture {
  [self.session startRunning];
}

- (void)stopAVCapture
{
  [self.session stopRunning];
  _session = nil;
  _points = nil;
  _beats = nil;
  _captureTimes = nil;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
  CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  CVPixelBufferLockBaseAddress(imageBuffer, 0);
  void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
  uint8_t *buf = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
  size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
  size_t width = CVPixelBufferGetWidth(imageBuffer);
  size_t height = CVPixelBufferGetHeight(imageBuffer);
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                               bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
  
  float low = lowPassValue(height, width, buf, bytesPerRow);
  [self render:context value:[NSNumber numberWithFloat:low]];
  
  CGImageRef quartzImage = CGBitmapContextCreateImage(context);
  
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  
  id renderedImage = CFBridgingRelease(quartzImage);
  
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    [CATransaction setDisableActions:YES];
    [CATransaction begin];
    imageLayer.contents = renderedImage;
    [CATransaction commit];
  });
}

- (void)render:(CGContextRef)context value:(NSNumber *)value
{
  NSNumber *point = [NSNumber numberWithFloat:[value floatValue] * -1];
  [self.points insertObject:point atIndex:0];
  if (self.isRecording) {
    NSNumber *time = [NSNumber numberWithDouble: [[NSDate date] timeIntervalSince1970] * 1000.0];
    [self.captureTimes insertObject:time atIndex:0];
    NSNumber *beat = [NSNumber numberWithInt:([value floatValue] + 1) * 100000];
    [self.beats insertObject:beat atIndex:0];
  }
  
  [self drawWithContext:context];
}

- (void)drawWithContext: (CGContextRef)context {
  if(self.points.count == 0) {
    return;
  }
  
  CGRect bounds = imageLayer.bounds;
  while(self.points.count > bounds.size.width / 2) {
    [self.points removeLastObject];
  }
  CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
  CGContextSetLineWidth(context, 2);
  CGContextBeginPath(context);
  
  CGFloat scale = [[UIScreen mainScreen] scale];
  
  // Flip coordinates from UIKit to Core Graphics
  CGContextSaveGState(context);
  CGContextTranslateCTM(context, .0f, bounds.size.height);
  CGContextScaleCTM(context, scale, scale);
  
  float xpos = bounds.size.width * scale;
  float ypos = [[self.points objectAtIndex:0] floatValue];
  
  CGContextMoveToPoint(context, xpos, ypos);
  for(int i = 1; i < self.points.count; i++) {
    xpos -= 5;
    float ypos = [[self.points objectAtIndex:i] floatValue];
    CGContextAddLineToPoint(context, xpos, bounds.size.height / 2 + ypos * bounds.size.height / 2);
  }
  CGContextStrokePath(context);
  CGContextRestoreGState(context);
}

- (void)showErrorAlert: (NSError *)error {
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error %d", (int)[error code]]
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
  [alertView show];
  return;
}

#pragma mark - configure capture

- (AVCaptureSession *)session {
  if (_session == nil) {
    _session = [AVCaptureSession new];
    [self configureSessionWithBlock:^() {
      [self configureSession];
    }];
  }
  return _session;
}

- (void)configureSessionWithBlock:(void (^)(void))configureBlock {
  [self.session beginConfiguration];
  configureBlock();
  [self.session commitConfiguration];
}

- (void)configureSession {
  [self configureDeviceInput];
  [self configureVideoDataOutput];
}

- (void)configureDeviceInput {
  AVCaptureDevice *device = [self defaultDevice];
  
  NSError *error = nil;
  AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
  if (error) {
    [self showErrorAlert:error];
  }
  
  if ([self.session canAddInput:deviceInput]) {
    [self.session addInput:deviceInput];
  }
}

- (AVCaptureDevice *)defaultDevice {
  AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  if([device isTorchModeSupported:AVCaptureTorchModeOn]) {
    [device lockForConfiguration:nil];
    [device setTorchMode:AVCaptureTorchModeOn];
    [device setActiveVideoMinFrameDuration:CMTimeMake(1, 10)];
    [device unlockForConfiguration];
  }
  return device;
}

- (void)configureVideoDataOutput {
  AVCaptureVideoDataOutput *videoDataOutput = [AVCaptureVideoDataOutput new];
  NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                     [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
  [videoDataOutput setVideoSettings:rgbOutputSettings];
  [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
  dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
  [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
  
  if ([self.session canAddOutput:videoDataOutput]) {
    [self.session addOutput:videoDataOutput];
  }
  AVCaptureConnection* connection = [videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
  [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
}

- (NSMutableArray *)points {
  if (_points == nil) {
    _points = [NSMutableArray new];
  }
  return _points;
}

- (NSMutableArray *)beats {
  if (_beats == nil) {
    _beats = [NSMutableArray new];
  }
  return _beats;
}

- (NSMutableArray *)captureTimes {
  if (_captureTimes == nil) {
    _captureTimes = [NSMutableArray new];
  }
  return _captureTimes;
}

@end
