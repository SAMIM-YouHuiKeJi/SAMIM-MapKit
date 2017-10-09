//
//  SAMIMMapModuleMAMapViewController.m
//  SAMIMMapModule
//
//  Created by ZIKong on 2017/9/30.
//  Copyright © 2017年 youhuikeji. All rights reserved.
//--verbose --allow-warnings --use-libraries

#import "SAMIMMapModuleMAMapViewController.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import <MAMapKit/MAMapKit.h>
#import "SAMIMMapSearchResultTableViewController.h"

#define kWeakSelf __weak typeof(self) weakSelf = self;

static NSIndexPath *signIndexPath = nil;
@interface SAMIMMapModuleMAMapViewController ()<MAMapViewDelegate,AMapSearchDelegate,UITableViewDelegate,UITableViewDataSource,UISearchResultsUpdating,UISearchBarDelegate>
{
    MAMapView *_mapView;
}
@property (nonatomic, strong) AMapSearchAPI *search;
@property (nonatomic, strong) AMapReGeocodeSearchRequest *regeo;
@property (nonatomic, strong) UITableView  *tableView;
@property (nonatomic, strong) NSMutableArray *dataMArray;
@property (nonatomic, strong) MAPointAnnotation *pointAnnotation;
@property (nonatomic, strong) CLLocation *location;
@property(nonatomic,strong)   UIBarButtonItem         *sendButton;
@property (nonatomic, strong) AMapPOI *selectedPoi;
    
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchController *searchControl;
@property (nonatomic, strong) SAMIMMapSearchResultTableViewController * resultTableView;

    @property (nonatomic, strong) NSString *province;
    @property (nonatomic, strong) NSString *city;
@end

@implementation SAMIMMapModuleMAMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    // Do any additional setup after loading the view.
    signIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//    self.mapKey = @"f25dfd8bb280effb099554e5048ee4ca";
    self.title = @"位置";
    ///地图需要v4.5.0及以上版本才必须要打开此选项（v4.5.0以下版本，需要手动配置info.plist）
    [[AMapServices sharedServices] setEnableHTTPS:YES];
    [AMapServices sharedServices].apiKey = self.mapKey;
    
    [self.view addSubview:self.searchBar];
    ///初始化地图
    
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 64+40, self.view.frame.size.width, self.view.frame.size.height/2+50-64-40)];
    ///把地图添加至view
    _mapView.delegate = self;
    _mapView.zoomLevel = 15;
    [self.view addSubview:_mapView];
    
//   NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
//    NSString *path = [[ myBundle resourcePath]stringByAppendingPathComponent:@"redPin.png"];

    NSInteger scale = [[UIScreen mainScreen] scale];
    NSBundle *currentBundle = [NSBundle bundleForClass:[self class]];
    NSString *name = [NSString stringWithFormat:@"%@@%zdx",@"greenPin",scale];
    NSString *dir = [NSString stringWithFormat:@"%@.bundle",@"SAMIM-MapKit"];
    NSString *path  = [currentBundle pathForResource:name ofType:@"png" inDirectory:dir];
    UIImage *image = [UIImage imageWithContentsOfFile:path];

  UIImageView *centerPin = [[UIImageView alloc] initWithImage:image];
//    UIImageView *centerPin = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"redPin"]];

    centerPin.frame = CGRectMake(CGRectGetMidX(_mapView.frame)-22, CGRectGetMidY(_mapView.frame)-36-64-40, 44, 72);
    [_mapView addSubview:centerPin];
    
    [self.view addSubview:self.tableView];
    
    ///如果您需要进入地图就显示定位小蓝点，则需要下面两行代码
    _mapView.showsUserLocation = YES;
    _mapView.userTrackingMode  = MAUserTrackingModeFollow;
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(_mapView.frame.size.width-60, _mapView.frame.size.height-70, 40, 40)];
    [_mapView addSubview:button];
//    NSString *locpath = [[ myBundle resourcePath]stringByAppendingPathComponent:@"loc.png"];
//
    NSString *name2 = [NSString stringWithFormat:@"%@@2x",@"loc"];
    NSString *dir2 = [NSString stringWithFormat:@"%@.bundle",@"SAMIM-MapKit"];
    NSString *path2  = [currentBundle pathForResource:name2 ofType:@"png" inDirectory:dir2];
    UIImage *image2 = [UIImage imageWithContentsOfFile:path2];
    [button setImage:image2 forState:UIControlStateNormal];
//    [button setImage:[UIImage imageNamed:@"loc"] forState:UIControlStateNormal];

    button.backgroundColor = [UIColor whiteColor];
    [button addTarget:self action:@selector(maptocenter) forControlEvents:UIControlEventTouchUpInside];
    _mapView.logoCenter = CGPointMake(CGRectGetMidX(button.frame), CGRectGetMidY(button.frame)+40-10);
    
    //逆地理编码（坐标转地址）
    self.search = [[AMapSearchAPI alloc] init];
    self.search.delegate = self;
    
    AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
    
    //    regeo.location                    = [AMapGeoPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    regeo.requireExtension            = YES;
    self.regeo = regeo;
    
    [self setUpRightNavButton];
    
    
}
- (void)setUpRightNavButton{
    UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onSend:)];
    self.navigationItem.rightBarButtonItem = item;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
    self.sendButton = item;
    self.sendButton.enabled = YES;
}

- (void)onSend:(id)sender{
    if (self.successBlock) {
        NSDictionary *locationInfo =  [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:self.selectedPoi.location.latitude],@"lat",[NSNumber numberWithDouble:self.selectedPoi.location.longitude],@"lng",self.selectedPoi.address,@"address", nil];
        self.successBlock(locationInfo);
    }
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];

}
- (void)maptocenter {
    [_mapView setCenterCoordinate:CLLocationCoordinate2DMake(self.location.coordinate.latitude, self.location.coordinate.longitude) animated:YES];
}
/**
 * @brief 位置或者设备方向更新后调用此接口
 * @param mapView 地图View
 * @param userLocation 用户定位信息(包括位置与设备方向等数据)
 * @param updatingLocation 标示是否是location数据更新, YES:location数据更新 NO:heading数据更新
 */
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation {
    if (updatingLocation) {
        NSLog(@"%@",userLocation.description);
        NSLog(@"%@",userLocation.location);
        NSLog(@"%@",userLocation.title);
        NSLog(@"%@",userLocation.subtitle);
        NSLog(@"%@",userLocation.heading);
        self.regeo.location = [AMapGeoPoint locationWithLatitude:userLocation.location.coordinate.latitude longitude:userLocation.location.coordinate.longitude];
        [self.search AMapReGoecodeSearch:self.regeo];
        self.location = userLocation.location;
        signIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        
    }
}

/**
 * @brief 定位失败后调用此接口
 * @param mapView 地图View
 * @param error 错误号，参考CLError.h中定义的错误号
 */
- (void)mapView:(MAMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    
}

/**
 * @brief 地图移动结束后调用此接口
 * @param mapView 地图view
 * @param wasUserAction 标识是否是用户动作
 */
- (void)mapView:(MAMapView *)mapView mapDidMoveByUser:(BOOL)wasUserAction{
    if(wasUserAction) {
        CLLocationCoordinate2D centerCoordinate = mapView.centerCoordinate;
        //        [self reverseGeoLocation:centerCoordinate];
        self.regeo.location = [AMapGeoPoint locationWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude];
        [self.search AMapReGoecodeSearch:self.regeo];
    }
}

/* 逆地理编码回调. */
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    if (response.regeocode != nil)
    {
        //解析response获取地址描述，具体解析见 Demo
        NSLog(@"%@",response.regeocode);
        self.city = response.regeocode.addressComponent.city;
        signIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        self.dataMArray = (NSMutableArray *)response.regeocode.pois;
        [self.tableView reloadData];
    }
}

- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
}

#pragma mark - tableview
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataMArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellid = @"gaodecellid";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellid];
        cell.textLabel.font  = [UIFont systemFontOfSize:15.0f];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:11.0f];
    }
    if(self.dataMArray.count > 0) {
        
        AMapPOI *poi = self.dataMArray[indexPath.row];
        cell.textLabel.text = poi.name;
        cell.detailTextLabel.text = poi.address;
        cell.textLabel.textColor = [UIColor darkGrayColor];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        
        if(indexPath.row == 0 && signIndexPath.row == 0){
            cell.textLabel.text = @"[位置]";
            cell.textLabel.textColor = [UIColor blueColor];
            cell.detailTextLabel.textColor = [UIColor blueColor];
        }
        if(indexPath == signIndexPath) {
            cell.accessoryType  = UITableViewCellAccessoryCheckmark;
            self.selectedPoi = poi;
        }
        else {
            cell.accessoryType  = UITableViewCellAccessoryNone;
        }
    }
   return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == signIndexPath.row && indexPath.section == signIndexPath.section) {
        return;
    }
    AMapPOI *poi = self.dataMArray[indexPath.row];
    [_mapView setCenterCoordinate:CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude) animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType =  UITableViewCellAccessoryCheckmark;
    
    if (indexPath.row != 0) {
        UITableViewCell *zeroCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        zeroCell.textLabel.textColor = [UIColor darkGrayColor];
        zeroCell.detailTextLabel.textColor = [UIColor grayColor];
    }
    else {
        cell.textLabel.textColor = [UIColor blueColor];
        cell.detailTextLabel.textColor = [UIColor blueColor];
    }
    
    UITableViewCell *signcell = [tableView cellForRowAtIndexPath:signIndexPath];
    signcell.accessoryType =  UITableViewCellAccessoryNone;
    signIndexPath = indexPath;
    
    self.selectedPoi = poi;
}
    
#pragma mark - UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self presentViewController:self.searchControl animated:YES completion:nil];
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    SAMIMMapSearchResultTableViewController *tableController = (SAMIMMapSearchResultTableViewController *)self.searchControl.searchResultsController;
    tableController.city = self.city;
    if (searchController.searchBar.text && !([searchController.searchBar.text length] <= 0)) {
        [tableController requestData:searchController.searchBar.text];
    }
}

#pragma mark - 懒加载
-(NSMutableArray *)dataMArray {
    if (!_dataMArray) {
        _dataMArray = [NSMutableArray arrayWithCapacity:30];
    }
    return _dataMArray;
}

-(UITableView *)tableView {
    if(!_tableView) {
        _tableView             = [[UITableView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/2+50, self.view.frame.size.width, self.view.frame.size.height/2-50) style:UITableViewStylePlain];
        _tableView.delegate    = self;
        _tableView.dataSource  = self;
    }
    return _tableView;
}

-(UISearchBar *)searchBar {
        if (!_searchBar) {

        _searchBar             = [[UISearchBar alloc] init];
        _searchBar.delegate    = self;
        _searchBar.placeholder = @"搜索";
        _searchBar.frame       = CGRectMake(0, 0, self.view.frame.size.width, 40);
        }
        return _searchBar;

}

- (SAMIMMapSearchResultTableViewController *)resultTableView {
        kWeakSelf
    __weak typeof(_mapView) weakSelfMapView = _mapView;
        if (_resultTableView == nil) {
            _resultTableView = [[SAMIMMapSearchResultTableViewController alloc] init];
            _resultTableView.mapKey = self.mapKey;
            _resultTableView.pushToVCBlock = ^(NSIndexPath *indexPath, id item) {
            AMapPOI *poi = item;

            [weakSelfMapView setCenterCoordinate:CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude) animated:YES];
            weakSelf.regeo.location = [AMapGeoPoint locationWithLatitude:poi.location.latitude longitude:poi.location.longitude];
            [weakSelf.search AMapReGoecodeSearch:weakSelf.regeo];
            weakSelf.location = [[CLLocation alloc] initWithLatitude:poi.location.latitude longitude:poi.location.longitude];
            signIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];

            };
        }
        return _resultTableView;
}
    
- (UISearchController *)searchControl {
    if (_searchControl == nil) {
        _searchControl = [[UISearchController alloc] initWithSearchResultsController:self.resultTableView];
        _searchControl.searchResultsUpdater = self;
        _searchControl.view.backgroundColor = [UIColor whiteColor];
    }
    return _searchControl;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
