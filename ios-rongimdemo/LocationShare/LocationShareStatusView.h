//
//  LocationShareStatusView.h
//  LocationSharer
//
//  Created by litao on 15/7/27.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RongIMLib/RongIMLib.h>

@protocol LocationShareStatusViewDelegate <NSObject>

- (void)onJoin;
- (void)onShowLocationShareView;
- (RCLocationShareStatus)getStatus;
@end


@interface LocationShareStatusView : UIView
@property (nonatomic, weak)id<LocationShareStatusViewDelegate> delegate;
- (void)updateText:(NSString *)statusText;
- (void)updateLocationShareStatus;
@end
