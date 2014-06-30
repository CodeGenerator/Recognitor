//
//  RVViewFinderViewModel.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 23/05/14.
//  Copyright (c) 2014 Recognitor. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "RVViewFinderViewModel.h"

#import "RVSendActionViewModel.h"
#import "RVSendActionViewController.h"
#import "RVPlateNumberExtractor.h"
#import "RVPlateNumber.h"

@interface RVViewFinderViewModel ()

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic, strong) dispatch_queue_t cameraQueue;

@property (nonatomic, assign, readwrite) BOOL cameraIsInitialized;
@property (nonatomic, assign) BOOL controllerIsOnScreen;

@end


@implementation RVViewFinderViewModel

- (instancetype)init
{
  self = [super init];
  if (self) {
    _cameraQueue = dispatch_queue_create("camera queue", 0);
    [self setupCaptureSession];
  }
  
  return self;
}

- (void)setupCaptureSession
{
  dispatch_async(self.cameraQueue, ^{
    self.captureSession = [AVCaptureSession new];
    self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    NSArray *availableVideoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *videoDevice = nil;
    for (AVCaptureDevice *device in availableVideoDevices) {
      if (device.position == AVCaptureDevicePositionBack) {
        videoDevice = device;
        break;
      }
    }
    
    if (videoDevice == nil) {
      NSLog(@"Can't find video device");
      self.captureSession = nil;
      return;
    }
    
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice
                                                                                   error:nil];
    if (videoDeviceInput == nil) {
      NSLog(@"Can't get video device input");
      self.captureSession = nil;
      return;
    }
    
    if (![self.captureSession canAddInput:videoDeviceInput]) {
      NSLog(@"Can't add video device input");
      self.captureSession = nil;
      return;
    }
    
    [self.captureSession addInput:videoDeviceInput];
    
    self.stillImageOutput = [AVCaptureStillImageOutput new];
    self.stillImageOutput.outputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    if (![self.captureSession canAddOutput:self.stillImageOutput]) {
      NSLog(@"Can't add still image output");
      self.captureSession = nil;
      self.stillImageOutput  = nil;
      return;
    }
    
    [self.captureSession addOutput:self.stillImageOutput];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      self.cameraIsInitialized = YES;
      self.videoPreviewLayer = previewLayer;
      [self.delegate viewModelDidFinishInitialization:self];
      
      if (self.controllerIsOnScreen) {
        dispatch_async(self.cameraQueue, ^{
          [self.captureSession startRunning];
        });
      }
    });
  });
}

- (void)controllerWillAppear
{
  self.controllerIsOnScreen = YES;
  if (!self.cameraIsInitialized) {
    return;
  }
  
  dispatch_async(self.cameraQueue, ^{
    [self.captureSession startRunning];
  });
}

- (void)controllerDidDisappear
{
  self.controllerIsOnScreen = NO;
  if (!self.cameraIsInitialized) {
    return;
  }
  
  dispatch_async(self.cameraQueue, ^{
    [self.captureSession stopRunning];
  });
}

- (AVCaptureVideoOrientation)videoOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
  switch (deviceOrientation) {
    case UIDeviceOrientationLandscapeLeft:
      return AVCaptureVideoOrientationLandscapeRight;
    case UIDeviceOrientationLandscapeRight:
      return AVCaptureVideoOrientationLandscapeLeft;
    case UIDeviceOrientationPortrait:
      return AVCaptureVideoOrientationPortrait;
    case UIDeviceOrientationPortraitUpsideDown:
      return AVCaptureVideoOrientationPortraitUpsideDown;
      
    default:
      return AVCaptureVideoOrientationPortrait;
      break;
  }
}

- (UIImageOrientation)imageOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
  switch (deviceOrientation) {
    case UIDeviceOrientationPortraitUpsideDown:
      return UIImageOrientationLeft;
    case UIDeviceOrientationLandscapeLeft:
      return UIImageOrientationUp;
    case UIDeviceOrientationLandscapeRight:
      return UIImageOrientationDown;
      
    case UIDeviceOrientationPortrait:
    default:
      return UIImageOrientationRight;
  }
}

- (void)captureImage
{
  AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
  UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
  if (stillImageConnection.supportsVideoOrientation) {
    stillImageConnection.videoOrientation = [self videoOrientationForDeviceOrientation:deviceOrientation];
  }
  
  [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
    if (error == nil) {
      CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(imageDataSampleBuffer);
      NSAssert(pixelBuffer != nil, @"Can't get image buffer");
      if (CVPixelBufferLockBaseAddress(pixelBuffer, 0) != kCVReturnSuccess)
      {
        NSAssert(nil, @"Can't lock image buffer");
        return;
      }
      
      const NSUInteger kBitPerComponent = 8;
      CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
      
      CGContextRef context = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(pixelBuffer),
                                                   CVPixelBufferGetWidth(pixelBuffer),
                                                   CVPixelBufferGetHeight(pixelBuffer),
                                                   kBitPerComponent,
                                                   CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                   colorSpace,
                                                   kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
      CGColorSpaceRelease(colorSpace);
      
      CGImageRef cgImage = CGBitmapContextCreateImage(context);
      CGContextRelease(context);
      CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
      
      if (cgImage == nil) {
        NSAssert(nil, @"Can't create image");
        return;
      }
      
      UIImageOrientation imageOrientaiton = [self imageOrientationForDeviceOrientation:deviceOrientation];
      UIImage *image = [UIImage imageWithCGImage:cgImage scale:0.0f orientation:imageOrientaiton];
      CGImageRelease(cgImage);
      [RVPlateNumberExtractor extractFromImage:image completion:^(NSArray *plateImages) {
        [self presentSendActionControllerWithOriginalImage:image platesImages:plateImages];
      }];
    }
  }];
}

- (void)presentSendActionControllerWithOriginalImage:(UIImage *)originalImage
                                        platesImages:(NSArray *)platesImages
{
  NSMutableArray *plateObjects = [NSMutableArray arrayWithCapacity:[platesImages count]];
  for (UIImage *plateImage in platesImages) {
    RVPlateNumber *plateObject = [[RVPlateNumber alloc] initWithImage:plateImage];
    [plateObject recognize];
    [plateObjects addObject:plateObject];
  }
  
  RVSendActionViewModel *viewModel = [[RVSendActionViewModel alloc] initWithOriginalImage:originalImage
                                                                                   plates:plateObjects];
  RVSendActionViewController *viewController = [[RVSendActionViewController alloc] initWithViewModel:viewModel];
  UINavigationController *navigationVC = [[UINavigationController alloc] initWithRootViewController:viewController];
  navigationVC.navigationBar.translucent = NO;
  navigationVC.navigationBar.barTintColor = [UIColor darkBackgroundColor];
  navigationVC.navigationBar.tintColor = [UIColor semiLightTextColor];
  navigationVC.navigationBar.barStyle = UIBarStyleBlack;
  
  [self.delegate presentViewController:navigationVC animated:YES completion:nil];
}

- (CALayer *)previewLayer
{
  return self.videoPreviewLayer;
}


@end
