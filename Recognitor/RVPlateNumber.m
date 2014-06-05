//
//  RVPlateNumber.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 30/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import "RVPlateNumber.h"
#import "RVBackend.h"


@interface RVPlateNumber ()

@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, assign, readwrite) RVPlateNumberRecognitionState recognitionState;
@property (nonatomic, strong, readwrite) NSError *lastError;

@property (nonatomic, assign) NSURLSessionTask *recognitionTask;

@end


@implementation RVPlateNumber

- (instancetype)initWithImage:(UIImage *)image
{
  self = [super init];
  if (self) {
    _image = image;
  }
  
  return self;
}

#pragma mark - Public methods

- (void)recognize
{
  MAIN_THREAD_ONLY
  
  if (self.recognitionState != RVPlateNumberRecognitionStateUnknown) {
    return;
  }
  self.recognitionState = RVPlateNumberRecognitionStateRecognizing;
  
  dispatch_async([[self class] requestsQueue], ^{
    
    NSData *imageData = UIImageJPEGRepresentation(self.image, 0.9f);
    self.recognitionTask = [[RVBackend sharedInstance] recognizePlateNumberFromData:imageData completion:^(NSString *plateNumber, NSError *error) {
      dispatch_async([[self class] requestsQueue], ^{
        self.recognitionTask = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
          if (error == nil) {
            self.string = plateNumber;
            self.recognitionState = RVPlateNumberRecognitionStateRecognized;
          } else {
            if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
              NSAssert(self.recognitionState == RVPlateNumberRecognitionStateCanceling, @"Canceled in wrong state");
              self.recognitionState = RVPlateNumberRecognitionStateUnknown;
              return;
            } else if ([error.domain isEqualToString:RVBackendErrorDomain] && (error.code == RVBackendErrorNotRecognized ||error.code == RVBackendErrorIncorrectlyRecognized)) {
              self.recognitionState = RVPlateNumberRecognitionStateNotRecognized;
            } else {
              self.recognitionState = RVPlateNumberRecognitionStateUnknown;
            }
            
            self.lastError = error;
          }
        });
      });
    }];
  });
}

- (void)cancelRecognition
{
  MAIN_THREAD_ONLY
  
  if (self.recognitionState == RVPlateNumberRecognitionStateRecognizing) {
    self.recognitionState = RVPlateNumberRecognitionStateCanceling;
    dispatch_async([[self class] requestsQueue], ^{
      [self.recognitionTask cancel];
    });
  }
}

- (void)blameWithCompletion:(void (^)(BOOL success))completion
{
  MAIN_THREAD_ONLY
  
  NSString *plateNumber = self.string;
  NSAssert(plateNumber != nil, @"We are in recognized state but there is no number!");
  dispatch_async([[self class] requestsQueue], ^{
    [[RVBackend sharedInstance] blamePlateNumber:plateNumber completion:^(NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
          self.lastError = error;
        }
        
        if (completion != nil) {
          completion(error == nil);
        }
      });
    }];
  });
}

- (void)requestBlameCountWithCompletion:(void (^)(BOOL success, NSUInteger))completion
{
  MAIN_THREAD_ONLY
  
  NSString *plateNumber = self.string;
  NSAssert(plateNumber != nil, @"We are in recognized state but there is no number!");
  dispatch_async([[self class] requestsQueue], ^{
    [[RVBackend sharedInstance] blameStatisticsForPlateNumber:plateNumber completion:^(NSUInteger blameCounter, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
          self.lastError = error;
        }
        
        if (completion != nil) {
          completion(error == nil, blameCounter);
        }
      });
    }];
  });
}

#pragma mark - Internal methods

+ (dispatch_queue_t)requestsQueue
{
  static dispatch_queue_t requestsQueue = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    requestsQueue = dispatch_queue_create("Plate number requests", 0);
  });
  
  return requestsQueue;
}

@end
