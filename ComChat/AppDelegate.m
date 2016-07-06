//
//  AppDelegate.m
//  ComChat
//
//  Created by D404 on 15/6/3.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "AppDelegate.h"
#import "Macros/Macros.h"
#import "RTCManager.h"
#import "SignInViewController.h"
#import "MainTabBarController.h"

@interface AppDelegate () {
    Reachability *hostReach;
}

@property (nonatomic, strong) SignInViewController *signInViewController;

@end

@implementation AppDelegate


- (void)application:(UIApplication*)application
didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"推送注册失败");
}
- (void)application:(UIApplication*)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken
                                              forKey:DEVICETOKEN];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
    
    NSNumber * number = [userDefault objectForKey:ICON_COUNT];
    NSNumber * count = [NSNumber numberWithInt:number.intValue + 1];
    
    [userDefault setObject:count forKey:ICON_COUNT];
    [userDefault synchronize];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = count.integerValue;
}

- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    NetworkStatus status = [curReach currentReachabilityStatus];
    
    if (status == NotReachable) {
        UIAlertView *alterView = [[UIAlertView alloc] initWithTitle:@"网络不可达" message:@"未检测到网络" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alterView show];
    }
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self startRegisterNotification];
//    //注册应用接受通知
//    if([[UIDevice currentDevice].systemVersion doubleValue] > 8.0){
//        UIUserNotificationSettings *setting = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil];
//        [application registerUserNotificationSettings:setting];
//    }
    
    if (launchOptions != nil && ![launchOptions isEqual:[NSNull null]]){
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager] connectThenSignIn];
    }else{
        /* 初始化导航条 */
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.signInViewController = [[SignInViewController alloc] init];
        
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:self.signInViewController];
        [navigation.navigationBar setBackgroundColor:[UIColor blueColor]];
        [navigation setNavigationBarHidden:YES];
        self.window.rootViewController = navigation;
    }
    
    
    [self.window makeKeyAndVisible];
    
    // 开启RTC引擎
//    [[RTCManager sharedManager] startEngine];
    
    /* 开启网络状态监听 */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    //TODO:这里建议改为xmpp_domin更合适
    hostReach = [Reachability reachabilityWithHostname:XMPP_HOST_NAME];
    [hostReach startNotifier];
    return YES;
}

//注册远程推送通知
- (void)startRegisterNotification
{
    if (IOS8_OR_LATER) {
        UIUserNotificationSettings* notificationSetting =
        [UIUserNotificationSettings
         settingsForTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound
         categories:nil];
        [[UIApplication sharedApplication]
         registerUserNotificationSettings:notificationSetting];
    }
    else {
        //注册远程推送通知
        [[UIApplication sharedApplication]
         registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    }
    if (IOS8_OR_LATER) {
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    NSLog(@"用户认证通过");
    
    NSLog(@"登录成功，进入主界面...");
    MainTabBarController *mainTabBarController = [[MainTabBarController alloc] init];
    mainTabBarController.selectedIndex = 0;
    self.window.rootViewController = mainTabBarController;
    
}

/**
 * This method is called if authentication fails.
 **/
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"登录失败"
                                                        message:@"账号或密码有误，请重新输入"
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
    [alertView show];
}
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
    NSNumber * number = [userDefault objectForKey:ICON_COUNT];
    [UIApplication sharedApplication].applicationIconBadgeNumber = number.integerValue;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
