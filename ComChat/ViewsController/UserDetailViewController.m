//
//  UserDetailViewController.m
//  ComChat
//
//  Created by D404 on 15/6/16.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "UserDetailViewController.h"
#import "UIViewAdditions.h"
#import "XMPPManager.h"
#import "Macros.h"
#import "UIView+Toast.h"
#import "AddContactViewController.h"
#import <MBProgressHUD.h>
#import "XMPPvCardTemp.h"
#import "FriendInviteMsgModel.h"
#import "ContactsViewModel.h"


@interface UserDetailViewController ()<MBProgressHUDDelegate>
{
    UIScrollView *mainScroll;
    MBProgressHUD *HUD;
    
    UITextField *nickNameField;
    UITextField *userGroupField;
}

@property (nonatomic, strong) NSString *userJID;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userNickName;
@property (nonatomic, strong) NSString *userGroup;

@property (nonatomic, strong) XMPPvCardTemp * vCard;


@property (nonatomic, assign) BOOL isFriend;
@property (nonatomic, assign) BOOL isSelf;



@end


@implementation UserDetailViewController

#pragma mark 初始化用户详细信息
- (instancetype)initWithUser:(NSString *)userName
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.contactsViewModel = [ContactsViewModel sharedViewModel];
        
        self.userName = userName;
        self.userJID = [NSString stringWithFormat:@"%@@%@", self.userName, XMPP_DOMAIN];
        
        [[XMPPManager sharedManager].xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
//        [self getCard:self.userJID];
        
    }
    return self;
}


//- (void)getCard:(NSString *)jidStr{
//    
//    XMPPIQ *iq = [XMPPIQ iqWithType:@"get"];
//    [iq addAttributeWithName:@"to" stringValue:jidStr/*好友的jid*/];
//    NSXMLElement *vElement = [NSXMLElement elementWithName:@"vCard" xmlns:@"vcard-temp"];
//    [iq addChild:vElement];
//   // 通过xmppStream发送请求，重新下载vcard：
//    [[XMPPManager sharedManager].xmppStream sendElement:iq];
//   
//}
//
//- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq{
//    
//    NSLog(@"==================名片:%@===============",iq);
//    
//    return YES;
//}






- (void)dealloc
{
    [[XMPPManager sharedManager].xmppRoster removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    
    self.navigationItem.title = @"个人资料";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.isSelf = [self judgeSelf:self.userName];
    self.isFriend = [self judgeFriend:self.userJID];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tabBarController.tabBar setHidden:YES];
    
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self setHidesBottomBarWhenPushed:NO];
    [super viewWillDisappear:animated];
}


#pragma mark 判断是否为自身
- (BOOL)judgeSelf:(NSString *)userName
{
    if ([[XMPPManager sharedManager].myJID.user isEqualToString:userName]) {
        return YES;
    }
    return NO;
}


#pragma mark 判断是否为好友
- (BOOL)judgeFriend:(NSString *)userJid
{
    return [self.contactsViewModel isExistInContactsList:userJid];
}


#pragma mark 添加好友
- (void)addFriend
{
    NSLog(@"申请添加%@为好友...", self.userName);
    
    XMPPJID *userJID = [XMPPJID jidWithString:self.userJID];
    
    if ([nickNameField.text isEqualToString:@""]) {
        self.userNickName = self.userName;
    }
    else {
        self.userNickName = nickNameField.text;
    }
    
    if ([userGroupField.text isEqualToString:@""]) {
        self.userGroup = @"我的好友";
    } else {
        self.userGroup = userGroupField.text;
    }
    NSArray *userGroupArray = [NSArray arrayWithObject:self.userGroup];
    
    [[XMPPManager sharedManager].xmppRoster addUser:userJID withNickname:self.userNickName groups:userGroupArray subscribeToPresence:YES];
}


#pragma mark 删除好友
- (void)deleteFriend
{
    NSLog(@"删除好友%@", self.userName);
    
    XMPPJID *userJID = [XMPPJID jidWithString:self.userJID];
    [[XMPPManager sharedManager].xmppRoster removeUser:userJID];
}






////////////////////////////////////////////////////////////////////////////
#pragma mark TableViewDelegate
////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.isSelf) {
        return 3;
    } else
        return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* userDetailCellIdentifier  = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:userDetailCellIdentifier];
    if (!cell) {
        if (indexPath.section == 0) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:userDetailCellIdentifier];
        } else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:userDetailCellIdentifier];
        }
    }
    
    switch (indexPath.section) {
        case 0:
        {
            UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 150)];
            UIImageView *bgImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 150)];
            bgImage.image = [UIImage imageNamed:@"user_info_bg@2x.jpg"];
            [bgView addSubview:bgImage];
            
            cell.backgroundView = bgView;
            break;
        }
        case 1:
        {
//            cell.imageView.image = [UIImage imageNamed:@"user_head_default"];
//            cell.textLabel.text = self.userName;
            UIImageView * headImgVC = [[UIImageView alloc]initWithFrame:CGRectMake(15, 0, 70, 70)];
            headImgVC.layer.cornerRadius = 35;
            headImgVC.layer.masksToBounds = YES;
            [cell.contentView addSubview:headImgVC];
            
            UILabel * userLabel = [[UILabel alloc]initWithFrame:CGRectMake(100, 20, SCREEN_WIDHT - 115, 30)];
            [cell.contentView addSubview:userLabel];
            NSData * photoData = [[XMPPManager sharedManager].xmppvCardAvatarModule photoDataForJID:[XMPPJID jidWithString:self.userJID]];
            if (photoData) {
                headImgVC.image = [UIImage imageWithData:photoData];
            }else{
                headImgVC.image = [UIImage imageNamed:@"user_head_default"];
            }
            userLabel.text = self.userName;
            
            break;
        }
        case 2:
        {
            cell.textLabel.text = @"用户昵称";
            cell.detailTextLabel.text = self.userName;
            break;
        }
        case 3:
        {
            self.isSelf = [self judgeSelf:self.userName];
            if (!self.isSelf) {
                self.isFriend = [self judgeFriend:self.userJID];
                if (self.isFriend) {
                    cell.textLabel.text = @"删除好友";
                    cell.backgroundColor = [UIColor redColor];
                } else {
                    cell.textLabel.text = @"加为好友";
                    cell.textLabel.backgroundColor = [UIColor cyanColor];
                }
                cell.textLabel.centerY = cell.centerY;
            }
            break;
        }
        default:
            break;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 3 && indexPath.row == 0) {
        self.isFriend = [self judgeFriend:self.userJID];
        if (self.isFriend) {        // 删除好友
            NSLog(@"删除好友%@", self.userName);
            
            XMPPJID *userJID = [XMPPJID jidWithString:self.userJID];
            [[XMPPManager sharedManager].xmppRoster removeUser:userJID];
            
        } else {                    // 添加好友
            HUD = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:HUD];
            
            HUD.delegate = self;
            HUD.labelText = @"正在发送好友邀请...";
            [HUD show:YES];
            
            XMPPJID *userJID = [XMPPJID jidWithString:self.userJID];
            NSArray *userGroupArray = [NSArray arrayWithObject:@"我的好友"];
            [[XMPPManager sharedManager].xmppRoster addUser:userJID withNickname:self.userName groups:userGroupArray subscribeToPresence:YES];
            
            /*
            AddContactViewController *addContactViewController = [[AddContactViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [addContactViewController initWithUser:self.userName];
            [self.navigationController pushViewController:addContactViewController animated:YES];
             */
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 3) {
        return 30.0f;
    }
    return 2.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 150.0f;
    } else if (indexPath.section == 1) {
        return 70.0f;
    }
    return 50.f;
}



////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////


//- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
//{
//    NSLog(@"userDetailViewController接收到Presence %@", [presence description]);
//    
//    // 请求加自己为好友
//    if ([[presence type] isEqualToString:@"subscribe"]) {
//        [self.view makeToast:@"已发送好友邀请" duration:0.5 position:CSToastPositionTop];
//        
//        [self.navigationController popViewControllerAnimated:YES];
//        
//    } else if ([[presence type] isEqualToString:@"unsubscribe"]) {
//        NSLog(@"已发送解除好友关系...");
//        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DELETE_TALK object:@{@"contactId":self.userJID} userInfo:nil];
//        [self.view makeToast:@"已发送解除好友关系" duration:0.5 position:CSToastPositionTop];
//        
//        [self.navigationController popToRootViewControllerAnimated:YES];
//    }
//}
//TODO: 李小涛添加，用来解决添加好友和解除好友之后的一系列问题。
- (void)xmppStream:(XMPPStream *)sender didSendIQ:(XMPPIQ *)iq
{
    NSLog(@"//user//XMPPManager xmppStream已发送IQ包%@",iq);
    for (NSXMLElement * query in iq.children) {
        for (NSXMLElement * item in query.children) {
            NSString * name = item.attributesAsDictionary[@"name"];
            if (name) {
                [self.view makeToast:@"已发送好友邀请" duration:0.5 position:CSToastPositionTop];
                #pragma mark --发送好友请求之后，缓存到本地。
                ContactsViewModel * contact = [ContactsViewModel sharedViewModel];
                FriendInviteMsgModel * friendMsg = [NSEntityDescription insertNewObjectForEntityForName:@"FriendInviteMsgModel" inManagedObjectContext:contact.friendInviteContext];
                friendMsg.userJid = item.attributesAsDictionary[@"jid"];
                friendMsg.isRead = @"0";
                friendMsg.isInvited = @"0";
                friendMsg.isWaitingAccept = @"1";
                friendMsg.keyId = [NSString stringWithFormat:@"%zi",contact.inviteContactsModel.count + 1];
                [contact.inviteContactsModel addObject:friendMsg];
                
                NSError * error = nil;
                if ([contact.friendInviteContext save:&error]) {
                    NSLog(@"好友邀请，保存失败了");
                }

                [self.navigationController popToRootViewControllerAnimated:YES];

            }else if([item.attributesAsDictionary[@"subscription"] isEqualToString:@"remove"]){
                NSLog(@"已发送解除好友关系...");
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DELETE_TALK object:@{@"contactId":self.userJID} userInfo:nil];
                [self.view makeToast:@"已发送解除好友关系" duration:0.5 position:CSToastPositionTop];
                [self.navigationController popToRootViewControllerAnimated:YES];

            }
        }
    }
    
    
    
}

/*- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item
{
    NSLog(@"AddContactViewController接收到Roster Item:%@", item);
    
    NSXMLElement *copyItem = [item copy];
    NSString *ask = [copyItem attributeStringValueForName:@"ask"];
    
    if ([ask isEqualToString:@"subscribe"]) {
        [HUD setHidden:YES];
        [self.view makeToast:@"已发送好友邀请" duration:0.5 position:CSToastPositionTop];
        
        [self.navigationController popViewControllerAnimated:YES];
        
//        int index = [[self.navigationController viewControllers] indexOfObject:self];
//        [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:index - 2] animated:YES];
 
    }
    
    NSString *subscription = [copyItem attributeStringValueForName:@"subscription"];
    
    if ([subscription isEqualToString:@"remove"]) {
        [self.view makeToast:@"已解除好友关系" duration:1.0 position:CSToastPositionCenter];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
        
//        int index = [[self.navigationController viewControllers] indexOfObject:self];
//        [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:index - 2] animated:YES];
    }
}
 */

/*
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item
{
    NSLog(@"UserDetailViewController接收到Roster Item:%@", item);
    
    NSXMLElement *copyItem = [item copy];
    NSString *subscription = [copyItem attributeStringValueForName:@"subscription"];
    
    if ([subscription isEqualToString:@"remove"]) {
        [self.view makeToast:@"已解除好友关系" duration:1.0 position:CSToastPositionCenter];
    }
}
 */





@end
