//
//  RVPlateTableViewCell.h
//  Recognitor
//
//  Created by Mikhail Korobkin on 31/05/14.
//  Copyright (c) 2014 Recognitor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RVPlateTableViewCell : UITableViewCell

@property (nonatomic, strong) UIImage *plateImage;
@property (nonatomic, copy) NSString *plateText;

@property (nonatomic, assign) BOOL loading;

@property (nonatomic, assign) BOOL withImage;

@end
