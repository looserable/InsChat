//
//  SelfSettingViewController.m
//  ComChat
//
//  Created by D404 on 15/6/11.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "ProfileViewController.h"
#import "UIViewAdditions.h"
#import "XMPPManager.h"
#import "XMPPvCardTemp.h"
#import <XMPPPresence.h>

#define CellIndentifier         @"ProfileCell"

@interface ProfileViewController ()<UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong) NSIndexPath *indexPath;

@property (nonatomic, strong) UIButton *headImage;
@property (nonatomic, strong) UILabel *userJid;
@property (nonatomic, strong) UILabel *nickName;
@property (nonatomic, strong) UITextField *nickNameField;

@property (nonatomic, retain) NSIndexPath *currentIndexPath;
@property (nonatomic, strong) UIImage * headImg;


@end


@implementation ProfileViewController


- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"账号管理";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIndentifier];
    self.tableView.allowsMultipleSelection = NO;
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

-(void)dealloc{
    [[XMPPManager sharedManager].xmppvCardTempModule removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}
#pragma mark 选择用户头像
- (IBAction)selectHeadImage:(id)sender
{
    UIActionSheet *myActionSheet = [[UIActionSheet alloc]
                                    initWithTitle:@"设置用户头像"
                                    delegate:self
                                    cancelButtonTitle:@"取消"
                                    destructiveButtonTitle:nil
                                    otherButtonTitles: @"从相册选择", @"拍照",nil];
    [myActionSheet showInView:self.view];
}


#pragma mark 更改昵称
- (IBAction)changeNickName:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"更改昵称"
                                                        message:@" "
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"确定", nil];
    alertView.tag = 10;
    self.nickNameField = [[UITextField alloc] init];
    [self.nickNameField setPlaceholder:@"请输入昵称"];
    self.nickNameField.backgroundColor = [UIColor whiteColor];
    self.nickNameField.frame = CGRectMake(alertView.centerX + 65, alertView.centerY + 3, alertView.width - 6, 25);
    [alertView addSubview:self.nickNameField];
    [alertView show];
}




#pragma mark 退出当前登录
- (IBAction)userSignOut:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"退出"
                                                        message:@"确定退出当前登录?"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"确定", nil];
    alertView.tag = 11;
    [alertView show];
    
}


#pragma mark 触发alterview
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 11) {
        if (buttonIndex == 0) {
            NSLog(@"取消退出");
        }
        else if (buttonIndex == 1) {
            [self dismissViewControllerAnimated:YES completion:^{}];
            [[XMPPManager sharedManager] disconnectFromServer];
        }
    } else if (alertView.tag == 10) {
        if (buttonIndex == 0) {
            NSLog(@"取消退出");
        }
        else if (buttonIndex == 1) {
            self.nickName.text = self.nickNameField.text;
        }
    }
    
}

#pragma mark 从相册或相机获取照片
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0:
        {
            // 从相册选择
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            //资源类型为图片库
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            picker.delegate = self;
            //设置选择后的图片可被编辑
            picker.allowsEditing = YES;
            //TODO: 李小涛修改，这里原本是self.navigationController进行的push操作，但是由于不能从一个navigationcontroller push到另一个navigationcontroller，所以这里应该用present。
            [self.navigationController presentViewController:picker animated:YES completion:^{}];
            break;
        }

        case 1:
        {
            // 从相机拍摄获取
            UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
            //判断是否有相机
            if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]){
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                picker.delegate = self;
                //设置拍照后的图片可被编辑
                picker.allowsEditing = YES;
                //资源类型为照相机
                picker.sourceType = sourceType;
                [self.navigationController presentViewController:picker animated:YES completion:^{}];
            }else {
                NSLog(@"该设备无摄像头");
            }
            break;
        }
        default:
            break;
    }
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    NSLog(@"更改用户头像...");
    //TODO: 上传头像
    self.headImg = image;
    [self uploadHeadImg:image];
    
    [picker dismissViewControllerAnimated:YES completion:^{}];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"取消选择图片");
    [picker dismissViewControllerAnimated:YES completion:^{}];
}






#pragma mark 发送用户在线或离线消息
- (void)sendPresenceShow:(NSString *)show
{
    NSLog(@"发送用户状态...");
    
    XMPPPresence *presence = [XMPPPresence presence];
    NSXMLElement *element_show = [NSXMLElement elementWithName:@"show" stringValue:show];
    [presence addChild:element_show];
    [[XMPPManager sharedManager].xmppStream sendElement:presence];
}



////////////////////////////////////////////////////////////////////////////
#pragma mark TableViewDelegate
////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    } else if (section == 1) {
        return @"状态";
    }
    else
        return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 2;
    } else {
        return 1;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        NSData *photoData = [[[XMPPManager sharedManager] xmppvCardAvatarModule]
                             photoDataForJID:[XMPPManager sharedManager].myJID];
        UIImageView * headImgView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 5, 50, 50)];
        headImgView.layer.cornerRadius = 25;
        headImgView.layer.masksToBounds = YES;
        headImgView.tag = 10000;
        [cell.contentView addSubview:headImgView];
        if (photoData) {
            headImgView.image = [UIImage imageWithData:photoData];
        }else{
            headImgView.image = [UIImage imageNamed:@"user_head_default"];
        }
        UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(70, 10, self.view.frame.size.width - 80, 40)];
        [cell.contentView addSubview:label];
        label.text = [XMPPManager sharedManager].myJID.user;       // TODO:仅显示用户名
    }
    
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"在线";
                break;
            case 1:
                cell.textLabel.text = @"隐身";
                break;
            default:
                break;
        }
        if (indexPath.section == self.currentIndexPath.section && indexPath.row == self.currentIndexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
    } else if (indexPath.section == 2) {
        cell.backgroundColor = [UIColor redColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.text = @"退 出";
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        UIActionSheet *myActionSheet = [[UIActionSheet alloc]
                                        initWithTitle:@"设置用户头像"
                                        delegate:self
                                        cancelButtonTitle:@"取消"
                                        destructiveButtonTitle:nil
                                        otherButtonTitles: @"从相册选择", @"拍照",nil];
        [myActionSheet showInView:self.view];
    } else if (indexPath.section == 1) {
        self.currentIndexPath = indexPath;
        [self.tableView reloadData];
        
        NSString *show = @"";
        switch (indexPath.row) {
            case 0:
                show = @"chat";
                break;
            case 1:
                show = @"away";
            default:
                break;
        }
        [self sendPresenceShow:show];
    } else if (indexPath.section == 2) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"退出"
                                                            message:@"确定退出当前登录?"
                                                           delegate:self
                                                  cancelButtonTitle:@"取消"
                                                  otherButtonTitles:@"确定", nil];
        alertView.tag = 11;
        [alertView show];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 20.f;
    } else if (section == 1) {
        return 40.0f;
    } else if (section == 2) {
        return 50.0f;
    }
    else
        return 20.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 2) {
        return 30.0f;
    }
    return 10.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 60;
    }
    else
        return 40;
}

- (void)uploadHeadImg:(UIImage *)image {
    
    XMPPvCardTempModule * xmppvCardTempModule = [XMPPManager sharedManager].xmppvCardTempModule;
    [xmppvCardTempModule addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    XMPPvCardAvatarModule * xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];

    
    [xmppvCardAvatarModule addDelegate:self delegateQueue:dispatch_get_main_queue()];
    dispatch_queue_t  global_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(global_queue, ^{
        NSString *xmppName = [NSString stringWithFormat:@"%d", 101];
        
        NSXMLElement *vCardXML = [NSXMLElement elementWithName:@"vCard"];
        [vCardXML addAttributeWithName:@"xmlns" stringValue:@"vcard-temp"];
        NSXMLElement *photoXML = [NSXMLElement elementWithName:@"PHOTO"];
        NSXMLElement *typeXML = [NSXMLElement elementWithName:@"TYPE" stringValue:@"image/jpeg"];
        
        NSData *dataFromImage = UIImageJPEGRepresentation(image, .1);//图片放缩
        NSXMLElement *binvalXML = [NSXMLElement elementWithName:@"BINVAL" stringValue:[dataFromImage base64EncodedStringWithOptions:0]];
        [photoXML addChild:typeXML];
        [photoXML addChild:binvalXML];
        [vCardXML addChild:photoXML];
        
        XMPPvCardTemp * myvCardTemp = xmppvCardTempModule.myvCardTemp;
        
        if (myvCardTemp) {
            myvCardTemp.photo = dataFromImage;
            [xmppvCardTempModule updateMyvCardTemp:myvCardTemp];
        } else {
            XMPPvCardTemp *newvCardTemp = [XMPPvCardTemp vCardTempFromElement:vCardXML];
            newvCardTemp.nickname = xmppName;
            [xmppvCardTempModule updateMyvCardTemp:newvCardTemp];
        }
    });
}

- (void)xmppvCardTempModuleDidUpdateMyvCard:(XMPPvCardTempModule *)vCardTempModule{
    NSLog(@"=================更新头像成功=======================");
    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIImageView * headImgVC = (UIImageView*)[cell viewWithTag:10000];
    headImgVC.image = self.headImg;
}
- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule failedToUpdateMyvCard:(NSXMLElement *)error{
    NSLog(@"=================更新头像失败=======================");
}





@end
