//
//  RVSendActionViewController.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 Recognitor. All rights reserved.
//

#import "RVSendActionViewController.h"
#import "RVSendActionViewModel.h"
#import "RVPlateTableViewCell.h"

const CGFloat kCellHeight = 50.0f;


@interface RVSendActionViewController () <RVSendActionViewModelDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) RVSendActionViewModel *viewModel;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation RVSendActionViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  return [self initWithViewModel:nil];
}

- (instancetype)initWithViewModel:(RVSendActionViewModel *)viewModel
{
  NSParameterAssert(viewModel != nil);
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _viewModel = viewModel;
    
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Отмена"
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(cancelSelection)];
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;

    self.navigationItem.title = @"Выберите номер";
  }
  
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor whiteColor];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
  self.tableView.backgroundColor = [UIColor lightBackgroundColor];
  self.tableView.separatorInset = UIEdgeInsetsZero;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  
  [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.viewModel.delegate = self;
  [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  self.viewModel.delegate = nil;
}

- (void)cancelSelection
{
  [self.viewModel didPressCancel];
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return UIInterfaceOrientationPortrait;
}

#pragma mark - RVSendActionViewModelDelegate implementation

- (void)viewModel:(RVSendActionViewModel *)viewModel didReceiveError:(NSError *)error
{
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Ошибка"
                                                      message:error.localizedDescription
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles: nil];
  [alertView show];
}

- (void)viewModel:(RVSendActionViewModel *)viewModel didChangePlateStateAtIndex:(NSUInteger)index
{
  [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                        withRowAnimation:UITableViewRowAnimationNone];
}

- (void)configureCell:(RVPlateTableViewCell *)cell atIndex:(NSUInteger)index
{
  if (index == [self.viewModel numberOfPlates]) {
    cell.withImage = NO;
    cell.loading = NO;
    cell.plateText = @"Выделить номер вручную";
    return;
  }
  
  cell.withImage = YES;
  cell.plateImage = [self.viewModel plateImageAtIndex:index];
  cell.plateText = [self.viewModel plateTextAtIndex:index];
  RVPlateViewState plateViewState = [self.viewModel plateViewStateAtIndex:index];
  cell.loading = plateViewState == RVPlateViewStateProcessing;
}

#pragma mark - UITableView delegates implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [self.viewModel numberOfPlates] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString * const kResusableIdentifier = @"PlateCell";
  RVPlateTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kResusableIdentifier];
  if (cell == nil) {
    cell = [[RVPlateTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kResusableIdentifier];
  }
  
  [self configureCell:cell atIndex:[indexPath row]];
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return kCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  [self.viewModel selectOptionAtIndex:[indexPath row]];
}

@end
