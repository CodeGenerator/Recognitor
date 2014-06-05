//
//  RVPlateTableViewCell.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 31/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import "RVPlateTableViewCell.h"

@interface RVPlateTableViewCell ()

@property (nonatomic, strong) UILabel *plateLabel;
@property (nonatomic, strong) UIImageView *plateImageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@end

@implementation RVPlateTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
      [self configureImageView];
      
      self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
      [self.contentView addSubview:self.activityView];
      
      self.plateLabel = [UILabel new];
      self.plateLabel.textColor = [UIColor lightTextColor];
      [self.contentView addSubview:self.plateLabel];
      
      self.contentView.backgroundColor = [UIColor lightBackgroundColor];
      self.backgroundColor = [UIColor lightBackgroundColor];
      
      self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.contentView.bounds];
      self.selectedBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      self.selectedBackgroundView.backgroundColor = [UIColor darkBackgroundColor];
      
    }
    return self;
}

- (void)setLoading:(BOOL)loading
{
  if (loading) {
    [self.activityView startAnimating];
  } else {
    [self.activityView stopAnimating];
  }
}

- (void)setWithImage:(BOOL)withImage
{
  self.imageView.hidden = withImage;
  [self setPlateLabelFrameWithImage:withImage];
}

- (void)configureImageView
{
  self.plateImageView = [[UIImageView alloc] init];
  self.plateImageView.contentMode = UIViewContentModeScaleAspectFit;
  self.plateImageView.clipsToBounds = YES;
  [self.contentView addSubview:self.plateImageView];
}

- (void)adjustFrames
{
  const CGFloat kImageViewLeftMargin = 10.0f;
  const CGFloat kImageViewTopAndBottomMargin = 5.0f;
  const CGFloat kImageViewWidth = 120.0f;
  self.plateImageView.frame = CGRectMake(kImageViewLeftMargin,
                                         kImageViewTopAndBottomMargin,
                                         kImageViewWidth,
                                         self.contentView.bounds.size.height - 2 * kImageViewTopAndBottomMargin);
  [self setPlateLabelFrameWithImage:self.withImage];
}

-(void)layoutSubviews
{
  [super layoutSubviews];
  [self adjustFrames];
}

- (void)setPlateLabelFrameWithImage:(BOOL)withImage
{
  _withImage = withImage;
  
  const CGFloat kLabelLeftMarginWithImage = 140.0f;
  const CGFloat kLabelLeftMarginWithoutImage = 10.0f;
  const CGFloat kLabelRightMargin = 10.0f;
  
  NSString const *testText = @"A001MP777";
  CGSize testTextSize = [testText sizeWithAttributes: @{NSFontAttributeName: self.plateLabel.font}];
  
  CGFloat kLeftMargin = withImage ? kLabelLeftMarginWithImage : kLabelLeftMarginWithoutImage;
  self.plateLabel.frame = CGRectMake(kLeftMargin,
                                     (self.contentView.bounds.size.height - testTextSize.height) / 2,
                                     self.contentView.bounds.size.width - kLeftMargin - kLabelRightMargin,
                                     testTextSize.height);
  
  self.activityView.center = self.plateLabel.center;
}

- (void)setPlateImage:(UIImage *)plateImage
{
  self.plateImageView.image = plateImage;
}

- (void)setPlateText:(NSString *)plateText
{
  self.plateLabel.text = plateText;
}

- (UIImage *)plateImage
{
  return self.plateImageView.image;
}

- (NSString *)plateText
{
  return self.plateLabel.text;
}


@end
