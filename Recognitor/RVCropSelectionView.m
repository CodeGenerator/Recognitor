//
//  RVCropSelectionView.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 28/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import "RVCropSelectionView.h"

@interface RVCropSelectionView ()

@property (nonatomic, strong) CAShapeLayer *maskLayer;
@property (nonatomic, strong) UIView *borderView;

@end


@implementation RVCropSelectionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
      [self createMaskLayer];
      self.layer.mask = self.maskLayer;
      
      _selectionFrame = CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height);
      
      self.borderView = [[UIView alloc] initWithFrame:_selectionFrame];
      self.borderView.backgroundColor = [UIColor clearColor];
      self.borderView.layer.borderWidth = 2.0f;
      self.borderView.layer.borderColor = [UIColor whiteColor].CGColor;
      [self addSubview:self.borderView];
    }
    return self;
}

- (void)createMaskLayer
{
  self.maskLayer = [CAShapeLayer layer];
  self.maskLayer.fillColor = [UIColor blackColor].CGColor;
  self.maskLayer.fillRule = kCAFillRuleEvenOdd;
  self.maskLayer.frame = self.layer.bounds;
}

- (UIBezierPath *)bezierPathForSelectionFrame:(CGRect)selectionFrame
{
  UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:self.maskLayer.bounds];
  [bezierPath appendPath:[UIBezierPath bezierPathWithRect:selectionFrame]];
  
  return bezierPath;
}

- (void)setSelectionFrame:(CGRect)selectionFrame
{
  _selectionFrame = selectionFrame;
  
  CGRect boundedRect = CGRectIntersection(self.layer.bounds, selectionFrame);
  UIBezierPath *bezierPath = [self bezierPathForSelectionFrame:boundedRect];
  self.maskLayer.path = bezierPath.CGPath;
  self.borderView.frame = CGRectIntersection(self.layer.bounds, CGRectInset(selectionFrame, -1.0f, -1.0f));
}

- (void)setFrame:(CGRect)frame
{
  [super setFrame:frame];
  self.maskLayer.frame = self.layer.bounds;
}

@end
