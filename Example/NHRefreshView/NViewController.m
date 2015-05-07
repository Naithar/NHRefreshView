//
//  NViewController.m
//  NHRefreshView
//
//  Created by Naithar on 05/05/2015.
//  Copyright (c) 2014 Naithar. All rights reserved.
//

#import "NViewController.h"
#import <NHRefreshView.h>

@interface NViewController ()<UITableViewDataSource, UITableViewDelegate, NHRefreshViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NHRefreshView *topRefreshView;
@property (strong, nonatomic) NHRefreshView *bottomRefreshView;

@end

@implementation NViewController

- (BOOL)refreshView:(NHRefreshView *)refreshView shouldChangeInsetsForScrollView:(UIScrollView *)scrollView withValue:(UIEdgeInsets)refreshViewInsets {
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);



    __weak typeof(self) weakSelf = self;

    self.topRefreshView = [[NHRefreshView alloc] initWithScrollView:self.tableView refreshBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.topRefreshView stopRefreshing];
        });
    }];

    self.topRefreshView.delegate = self;

    self.bottomRefreshView = [[NHRefreshView alloc] initWithScrollView:self.tableView direction:NHRefreshViewDirectionBottom refreshBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.bottomRefreshView stopRefreshing];
        });
    }];

    self.tableView.backgroundColor = [UIColor lightGrayColor];


//    [self.view layoutIfNeeded];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
}

- (void)dealloc {
//    [self.topRefreshView removeFromSuperview];
}

@end