//
//  SAMIMMapSearchResultTableViewController.h
//  MapTest
//
//  Created by ZIKong on 2017/10/9.
//  Copyright © 2017年 youhuikeji. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^PushToVCBlock) (NSIndexPath *indexPath, id item);

@interface SAMIMMapSearchResultTableViewController : UITableViewController
@property (nonatomic, copy) NSString      *city;
@property (nonatomic, copy) NSString      *mapKey;

@property (nonatomic, copy) PushToVCBlock pushToVCBlock;

- (void)requestData:(NSString *)keyword ;

@end
