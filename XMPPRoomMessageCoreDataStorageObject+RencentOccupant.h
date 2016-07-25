//
//  XMPPRoomMessageCoreDataStorageObject+RencentOccupant.h
//  ComChat
//
//  Created by john on 16/7/22.
//  Copyright © 2016年 D404. All rights reserved.
//

#import "XMPPRoomMessageCoreDataStorageObject.h"

@interface XMPPRoomMessageCoreDataStorageObject (RencentOccupant)

@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *chatRecord;
@property (nonatomic, strong) NSNumber *unreadMessages;     //
@property (nonatomic, assign) BOOL isChatting;              // 是否正在聊天


@end
