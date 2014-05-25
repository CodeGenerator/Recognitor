//
//  RVBackend.h
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^RecognizePlateCompletion)(NSString *plateNumber, NSError *error);
typedef void(^BlamePlateCompletion)(NSError *error);
typedef void(^BlameStatisticsCompletion)(NSUInteger blameCounter, NSError *error);


@interface RVBackend : NSObject

+ (instancetype)sharedInstance;

- (void)recognizePlateNumberFromData:(NSData *)data
                          completion:(RecognizePlateCompletion)completion;

- (void)blamePlateNumber:(NSString *)plateNumber completion:(BlamePlateCompletion)completion;

- (void)blameStatisticsForPlateNumber:(NSString *)plateNumber completion:(BlameStatisticsCompletion)completion;

- (BOOL)isValidPlateNumber:(NSString *)plateNumber;

@end
