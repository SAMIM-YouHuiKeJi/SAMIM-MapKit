//
//  SAMIMMapSearchResultTableViewController.m
//  MapTest
//
//  Created by ZIKong on 2017/10/9.
//  Copyright © 2017年 youhuikeji. All rights reserved.
//

#import "SAMIMMapSearchResultTableViewController.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

@interface SAMIMMapSearchResultTableViewController ()<AMapSearchDelegate>
@property (nonatomic, strong) AMapSearchAPI *search;
@property (nonatomic, strong) NSArray       *dataArray;
@end

@implementation SAMIMMapSearchResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [AMapServices sharedServices].apiKey = self.mapKey;//@"f25dfd8bb280effb099554e5048ee4ca";

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.search = [[AMapSearchAPI alloc] init];
    self.search.delegate = self;

}
- (void)requestData:(NSString *)keyword {
    
    AMapPOIKeywordsSearchRequest *request = [[AMapPOIKeywordsSearchRequest alloc] init];
    
    request.keywords            = keyword;
    request.city                = self.city;
    request.requireExtension    = YES;
    
    /*  搜索SDK 3.2.0 中新增加的功能，只搜索本城市的POI。*/
    request.cityLimit           = YES;
    request.requireSubPOIs      = YES;

    [self.search AMapPOIKeywordsSearch:request];
}

    /* POI 搜索回调. */
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response

{
        if (response.pois.count == 0)
        {
            return;
        }
        
        //解析response获取POI信息，具体解析见 Demo
        self.dataArray = response.pois;
        [self.tableView reloadData];
}

/**
 * @brief 当请求发生错误时，会调用代理的此方法.
 * @param request 发生错误的请求.
 * @param error   返回的错误.
 */
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error{
    NSLog(@"%@",error);
}
    
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellid = @"resultCellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellid];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellid];
    }
    if(self.dataArray.count > 0) {
        AMapPOI *mapPoi = self.dataArray[indexPath.row];
        cell.textLabel.text = mapPoi.name;
        cell.detailTextLabel.text = mapPoi.address;
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
     [self dismissViewControllerAnimated:YES completion:^{
         if (self.pushToVCBlock) {
             self.pushToVCBlock(indexPath, self.dataArray[indexPath.row]);
         }
     }];
}

@end
