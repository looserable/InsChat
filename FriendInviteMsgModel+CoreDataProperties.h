//
//  FriendInviteMsgModel+CoreDataProperties.h
//  ComChat
//
//  Created by john on 16/7/18.
//  Copyright © 2016年 D404. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "FriendInviteMsgModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface FriendInviteMsgModel (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *userJid;
@property (nullable, nonatomic, retain) NSString *isRead;
/**
 *  针对的是别人发出的邀请，所以这里是被邀请。在新好友页面，按钮显示为同意或者拒绝
 */
@property (nullable, nonatomic, retain) NSString *isInvited;
/**
 *  针对的是给别人发出的邀请，这里用了等待，在新好友页面，按钮效果是灰色不可点，并且显示等待验证。
 */
@property (nullable, nonatomic, retain) NSString *isWaitingAccept;
@property (nullable, nonatomic, retain) NSString *keyId;

@end

NS_ASSUME_NONNULL_END
