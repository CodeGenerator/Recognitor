//
//  RVBackend.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import "RVBackend.h"

@interface RVBackend () <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *sessionQueue;

@end

@implementation RVBackend

- (instancetype)init
{
  self = [super init];
  if (self) {
    _sessionQueue = [[NSOperationQueue alloc] init];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:_sessionQueue];
  }
  
  return self;
}

+ (instancetype)sharedInstance
{
  static RVBackend *sharedBackend = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedBackend = [RVBackend new];
  });
  
  return sharedBackend;
}

- (void)recognizePlateNumberFromData:(NSData *)data completion:(RecognizePlateCompletion)completion
{
  NSString *const kRecognizeBackendURL = @"http://193.138.232.71:10000/result";
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSURL *uploadURL = [NSURL URLWithString:kRecognizeBackendURL];
    NSMutableURLRequest *uploadRequest = [NSMutableURLRequest requestWithURL:uploadURL];
    uploadRequest.HTTPMethod = @"POST";
    NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithRequest:uploadRequest fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        NSString *plateNumber = nil;
        NSError *resultError = nil;
        if (error == nil) {
          NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
          NSLog(@"Got recognition response: %@", responseString);
          NSArray *responseComponents = [responseString componentsSeparatedByString:@"\r\n"];
          if (3 <= [responseComponents count] && [responseComponents[0] length] > 0 && ![responseComponents[0] isEqualToString:@" "]) {
            plateNumber = responseComponents[0];
            if (![self isValidPlateNumber:plateNumber]) {
              plateNumber = nil;
              resultError = [NSError errorWithDomain:@"Backend" code:1 userInfo:@{NSLocalizedDescriptionKey : @"Номер распознан некорректно"}];
            }
          } else {
            resultError = [NSError errorWithDomain:@"Backend" code:0 userInfo:@{NSLocalizedDescriptionKey : @"Номер не распознан"}];
          }
        } else {
          resultError = error;
        }
        if (completion != nil) {
          completion(plateNumber, resultError);
        }
      });
    }];
                     
    [uploadTask resume];
  });
}

- (BOOL)isValidPlateNumber:(NSString *)plateNumber
{
  // TOOD: Add russian plate number validation
  return YES;
}

- (void)blamePlateNumber:(NSString *)plateNumber completion:(BlamePlateCompletion)completion
{
  NSString *const kBlameBackendURL = @"http://193.138.232.71:10000/swear";
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSURL *blameURL = [NSURL URLWithString:kBlameBackendURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:blameURL];
    request.HTTPMethod = @"POST";
    NSURLSessionDataTask *blameTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (completion != nil) {
          completion(error);
        }
      });
    }];
    
    [blameTask resume];
  });
}

- (void)blameStatisticsForPlateNumber:(NSString *)plateNumber completion:(BlameStatisticsCompletion)completion
{
  NSString *const kStatisticsBackendURL = @"http://193.138.232.71:10000/checkplate";
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSURL *statisticsURL = [NSURL URLWithString:kStatisticsBackendURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:statisticsURL];
    request.HTTPMethod = @"POST";
    
    NSString *bodyString = [@[plateNumber, @"123"] componentsJoinedByString:@"\r\n"];
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = bodyData;
    
    NSURLSessionDataTask *statisticsTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger blameCounter = 0;
        if (error == nil) {
          NSString *blameCounterString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
          blameCounter = [blameCounterString integerValue];
        }
        
        if (completion != nil) {
          completion(blameCounter, error);
        }
      });
    }];
    
    [statisticsTask resume];
  });
}

@end
