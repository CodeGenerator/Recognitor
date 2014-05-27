//
//  RVPlateNumberExtractor.h
//  Recognitor
//
//  Created by Mikhail Korobkin on 27/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RVPlateNumberExtractor : NSObject

+ (void)extractFromImage:(UIImage *)image completion:(void (^)(NSArray *plateImages))completion;

@end
