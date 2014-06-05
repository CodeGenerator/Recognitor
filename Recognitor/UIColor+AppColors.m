//
//  UIColor+AppColors.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 05/06/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import "UIColor+AppColors.h"

@implementation UIColor (AppColors)

+ (UIColor *)darkTextColor
{
  return [UIColor colorWithRed:46.0f / 255.0f
                         green:45.0f / 255.0f
                          blue:45.0f / 255.0f
                         alpha:1.0f];
}

+ (UIColor *)lightTextColor
{
  return [UIColor whiteColor];
}

+ (UIColor *)semiLightTextColor
{
  return [UIColor colorWithWhite:0.9f alpha:1.0f];
}

+ (UIColor *)darkBackgroundColor
{
  return [UIColor colorWithRed:122.0f / 255.0f
                         green:27.0f / 255.0f
                          blue:27.0f / 255.0f
                         alpha:1.0f];
}

+ (UIColor *)lightBackgroundColor
{
  return [UIColor colorWithRed:225.0f / 255.0f
                         green:49.0f / 255.0f
                          blue:49.0f / 255.0f
                         alpha:1.0f];
}

@end
