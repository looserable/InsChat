//
//  MessageViewModel.h
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RVMViewModel.h"
#import "XMPPMessageArchiving_Contact_CoreDataObject+RecentContact.h"
#import "XMPPRoomOccupantCoreDataStorageObject+RencentOccupant.h"
#import "XMPPRoomMessageCoreDataStorageObject+RencentOccupant.h"


@interface MessageViewModel : RVMViewModel

@property (nonatomic, readonly) RACSignal *updatedContentSignal;
@property (nonatomic, readonly) NSNumber *totalUnreadMessagesNum;

@property (nonatomic, strong) NSMutableArray *totalContactsMessageArray;
@property (nonatomic, strong) NSMutableArray *totalRoomsMessageArray;
@property (nonatomic, strong) NSMutableArray *totalResultsMessageArray;

+ (instancetype)sharedViewModel;

- (void)decreaseTotalUnreadMessagesCountWithValue:(NSInteger)count;
- (BOOL)deleteRecentContactWithJid:(XMPPJID *)recentContactJid;
- (BOOL)deleteRecentRoomWithRoomJid:(XMPPJID *)recentRoomJid;
- (BOOL)resetUnreadMessageCountForCurrentContact:(XMPPJID *)contactJid;
- (BOOL)resetUnreadMessageCountForCurrentRoom:(XMPPJID *)roomJid;

- (void)fetchRecentContacts;
- (void)fetchRecentRooms;
- (void)mergeAllFetchedResults;

- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;
//- (XMPPMessageArchiving_Contact_CoreDataObject *)objectAtIndexPath:(NSIndexPath *)indexPath;
//- (XMPPRoomOccupantCoreDataStorageObject *)objectOfRoomAtIndexPath:(NSIndexPath *)indexPath;

- (void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteObjectOfRoomAtIndexPath:(NSIndexPath *)indexPath;
//TODO: 李小涛添加，用来解决好友删除之后，和它的会话不能删除的问题
- (void)deleteTalkWithJidStr:(NSString *)userJid;

@end
