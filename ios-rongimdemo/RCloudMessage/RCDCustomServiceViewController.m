//
//  RCDCustomServiceViewController.m
//  RCloudMessage
//
//  Created by litao on 16/2/23.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCDCustomServiceViewController.h"

@implementation RCDCustomServiceViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self notifyUpdateUnreadMessageCount];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//客服VC左按键注册的selector是customServiceLeftCurrentViewController，这个函数会弹出评价，
//等待用户评价结束后调用如下函数离开当前VC。
- (void)leftBarButtonItemPressed:(id)sender {
    //需要调用super的实现
    [super leftBarButtonItemPressed:sender];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)commentCustomerServiceAndQuit:(int)serviceStatus {
    [super commentCustomerServiceAndQuit:serviceStatus];
    //如果要自己来弹出评价界面，请把上面的super去掉，在这里弹出评价界面，然后把用户的评价结果调用RongIMLib的接口发送评价到客服后台。最后调用leftBarButtonItemPressed离开当前VC
    //评价人工服务和机器人服务的方法是：
    //[[RCIMClient sharedRCIMClient] evaluateCustomService:@"kefuId" humanValue:5 suggest:@"很棒"];
    //[[RCIMClient sharedRCIMClient] evaluateCustomService:@"kefuId" robotValue:YES suggest:@"萌哒哒"];
}

- (void)notifyUpdateUnreadMessageCount {
    __weak typeof(&*self) __weakself = self;
    int count = [[RCIMClient sharedRCIMClient] getUnreadCount:@[
                                                                @(ConversationType_PRIVATE),
                                                                @(ConversationType_DISCUSSION),
                                                                @(ConversationType_APPSERVICE),
                                                                @(ConversationType_PUBLICSERVICE),
                                                                @(ConversationType_GROUP)
                                                                ]];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *backString = nil;
        if (count > 0 && count < 1000) {
            backString = [NSString stringWithFormat:@"返回(%d)", count];
        } else if (count >= 1000) {
            backString = @"返回(...)";
        } else {
            backString = @"返回";
        }
        UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        backBtn.frame = CGRectMake(0, 6, 87, 23);
        UIImageView *backImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navigator_btn_back"]];
        backImg.frame = CGRectMake(-10, 0, 22, 22);
        [backBtn addSubview:backImg];
        UILabel *backText = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, 85, 22)];
        backText.text = backString;//NSLocalizedStringFromTable(@"Back", @"RongCloudKit", nil);
        //   backText.font = [UIFont systemFontOfSize:17];
        [backText setBackgroundColor:[UIColor clearColor]];
        [backText setTextColor:[UIColor whiteColor]];
        [backBtn addSubview:backText];
        [backBtn addTarget:__weakself action:@selector(customServiceLeftCurrentViewController) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
        [__weakself.navigationItem setLeftBarButtonItem:leftButton];
    });
}

@end
