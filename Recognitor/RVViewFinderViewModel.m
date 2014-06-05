//
//  RVViewFinderViewModel.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 23/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
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
    self.stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
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

//- (UIImageOrientation)currentImageOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
//{
//  switch
//}

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

- (void)captureImage
{
  AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
  stillImageConnection.videoOrientation = [self videoOrientationForDeviceOrientation:[UIDevice currentDevice].orientation];
  [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
    if (error == nil) {
      // TODO: optimize! just read values from buffer (use another pixel format)
      NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
      UIImage *image = [UIImage imageWithData:jpegData];
      [RVPlateNumberExtractor extractFromImage:image completion:^(NSArray *plateImages) {
        [self presentSendActionControllerWithOriginalImageData:jpegData platesImages:plateImages];
      }];
    }
  }];
}

- (void)presentSendActionControllerWithOriginalImageData:(NSData *)originalImageData
                                            platesImages:(NSArray *)platesImages
{
  NSMutableArray *plateObjects = [NSMutableArray arrayWithCapacity:[platesImages count]];
  for (UIImage *plateImage in platesImages) {
    RVPlateNumber *plateObject = [[RVPlateNumber alloc] initWithImage:plateImage];
    [plateObject recognize];
    [plateObjects addObject:plateObject];
  }
  
  RVSendActionViewModel *viewModel = [[RVSendActionViewModel alloc] initWithOriginalImageData:originalImageData
                                                                                       plates:plateObjects];
  RVSendActionViewController *viewController = [[RVSendActionViewController alloc] initWithViewModel:viewModel];
  UINavigationController *navigationVC = [[UINavigationController alloc] initWithRootViewController:viewController];
  navigationVC.navigationBar.translucent = NO;
  
  [self.delegate presentViewController:navigationVC animated:YES completion:nil];
}

- (CALayer *)previewLayer
{
  return self.videoPreviewLayer;
}


@end
