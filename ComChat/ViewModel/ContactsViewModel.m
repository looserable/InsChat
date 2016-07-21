//
//  ContactsViewModel.m
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "ContactsViewModel.h"
#import <RACSubject.h>
#import <ReactiveCocoa.h>
#import "XMPPManager.h"
#import <XMPPMessageArchiving_Contact_CoreDataObject.h>
#import <XMPPGroupCoreDataStorageObject.h>
#import "Macros.h"
#import "XMPP+IM.h"
#import "XMPPRoomManager.h"
#import "FriendInviteMsgModel.h"


@interface ContactsViewModel()<NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) RACSubject *updatedContentSignal;
@property (nonatomic, strong) NSMutableArray *contactModel;
@property (nonatomic, strong) NSMutableArray *groupModel;
//@property (nonatomic, strong) NSMutableArray *inviteContactsModel;
@property (nonatomic, strong) NSMutableArray *searchContactsModel;

@property (nonatomic, assign) NSNumber *unsubscribedCountNum;

@end


@implementation ContactsViewModel

#pragma mark 共享View Model
+ (instancetype)sharedViewModel
{
    static ContactsViewModel *_shareedViewModel = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _shareedViewModel = [[self alloc] init];
    });
    return _shareedViewModel;
}

- (void)dealloc
{
    [[XMPPManager sharedManager].xmppRoster removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    self.inviteContactsModel = nil;
    self.searchContactsModel = nil;
}


#pragma mark 初始化
- (instancetype)init
{
    if (self = [super init]) {
        self.model = [[XMPPManager sharedManager] managedObjectContext_roster];
        
        [[XMPPManager sharedManager].xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppMUC addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        self.updatedContentSignal = [[RACSubject subject] setNameWithFormat:@"%@ updatedContentSignal", NSStringFromClass([ContactsViewModel class])];
        self.inviteContactsModel = [[NSMutableArray alloc] init];
        self.unsubscribedCountNum = 0;
        
        self.searchContactsModel = [[NSMutableArray alloc] init];
        
        [self createDB];
        
        @weakify(self)
        [self.didBecomeActiveSignal subscribeNext:^(id x) {
            @strongify(self)
            [self fetchUsers];
//            [self fetchInviteList];
        }];
        
        RAC(self, active) = [RACObserve([XMPPManager sharedManager], myJID) map:^id(id value) {
            if (value) {
                return @(YES);
            }
            return @(NO);
        }];
        
        
    }
    return self;
}

- (void)createDB{
    
    NSString *doc  = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [doc stringByAppendingPathComponent:@"/FriendInviteMsgModel.db"];//注意不是:stringByAppendingString
    
    NSURL *url = [NSURL fileURLWithPath:path];
    NSLog(@"-----------------------------------");
    NSLog(@"data : %@",path);
    
    //创建文件,并且打开数据库文件
    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    //给存储器指定存储的类型
    NSError *error;
    NSPersistentStore *store = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error];
    if (store == nil) {
        [NSException raise:@"添加数据库错误" format:@"%@",[error localizedDescription]];
    }
    
    //创建图形上下文
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;
    self.friendInviteContext = context;
    
}


#pragma mark 搜索联系人
- (void)searchContacts:(NSString *)searchTerm
{
    NSLog(@"搜索联系人: %@", searchTerm);
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    [query addAttributeWithName:@"xmlns" stringValue:@"jabber:iq:search"];
    
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    [x addAttributeWithName:@"type" stringValue:@"submit"];
    
    NSXMLElement *formType = [NSXMLElement elementWithName:@"field"];
    [formType addAttributeWithName:@"type" stringValue:@"hidden"];
    [formType addAttributeWithName:@"var" stringValue:@"FORM_TYPE"];
    [formType addChild:[NSXMLElement elementWithName:@"value" stringValue:@"jabber:iq:search"]];
    
    
    NSXMLElement *userName = [NSXMLElement elementWithName:@"field"];
    [userName addAttributeWithName:@"var" stringValue:@"Username"];
    [userName addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    
    NSXMLElement *name = [NSXMLElement elementWithName:@"field"];
    [name addAttributeWithName:@"var" stringValue:@"Name"];
    [name addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    
    NSXMLElement *email = [NSXMLElement elementWithName:@"field"];
    [email addAttributeWithName:@"var" stringValue:@"Email"];
    [email addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    
    
    NSXMLElement *search = [NSXMLElement elementWithName:@"field"];
    [search addAttributeWithName:@"var" stringValue:@"search"];
    [search addChild:[NSXMLElement elementWithName:@"value" stringValue:searchTerm]];
    
    [x addChild:formType];
    [x addChild:userName];
    //TODO: 李小涛添加   开始的时候这里没有将name 和email 加入到子结点中导致的搜索失败。所以切记搜索的各个条件一定要加的完整。
    [x addChild:name];
    [x addChild:email];
    [x addChild:search];
    [query addChild:x];
    
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    [iq addAttributeWithName:@"type" stringValue:@"set"];
    [iq addAttributeWithName:@"id" stringValue:@"searchByUserName"];
    [iq addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"search.%@", XMPP_DOMAIN]];
    [iq addChild:query];
    
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}


#pragma mark 获取联系人列表
- (void)fetchUsers
{
    [self setPredicateForFetchContacts];
    
    NSError *error = nil;
    if (![self.fetchedUsersResultsController performFetch:&error]) {
        NSLog(@"获取联系人列表失败");
    }
    else {
        NSArray *dataArray = [self.fetchedUsersResultsController fetchedObjects];
        NSLog(@"获取到的好友数 = %zi", dataArray.count);
        if (dataArray.count > 0) {
            if (!self.contactModel) {
                self.contactModel = [[NSMutableArray alloc] initWithArray:dataArray];
            } else {
                [self.contactModel setArray:dataArray];
            }
            
            NSMutableDictionary *groupDic = [[NSMutableDictionary alloc] init];
            NSMutableArray *groupArray = [[NSMutableArray alloc] init];
            
            for (XMPPUserCoreDataStorageObject *user in dataArray) {
                if ([user.groups allObjects].count == 0) {
                    NSLog(@"用户组为空，默认添加到我的好友分组");
                    [groupDic addEntriesFromDictionary:@{@"我的好友" : [[NSMutableArray alloc] init]}];
                    
                    if (![groupArray containsObject:@"我的好友"]) {
                        [groupArray addObject:@"我的好友"];
                    }
                } else {
                    XMPPGroupCoreDataStorageObject *group = [user.groups allObjects][0];
                    NSLog(@"group.name = %@", group.name);
                    [groupDic addEntriesFromDictionary:@{group.name : [[NSMutableArray alloc] init]}];
                    
                    if (![groupArray containsObject:group.name]) {
                        [groupArray addObject:group.name];
                    }
                }
            }

            for (XMPPUserCoreDataStorageObject *user in dataArray) {
                if ([user.groups allObjects].count == 0) {
                    [groupDic[@"我的好友"] addObject:user];
                } else {
                    XMPPGroupCoreDataStorageObject *group = [user.groups allObjects][0];
                    [groupDic[group.name] addObject:user];
                }
            }
            
            self.groupModel = [[NSMutableArray alloc] initWithCapacity:[groupDic allKeys].count];
            for (NSString *groupName in groupArray) {
                NSDictionary *userDic = @{groupName : groupDic[groupName]};
                [self.groupModel addObject:userDic];
            }

            //[self pickBothFriendFromRosterArray:dataArray];
        }else{
            //TODO: 解决当只有一个好友并删除之后，页面的刷新的问题。
            self.groupModel = [[NSMutableArray alloc]init];
        }
        [(RACSubject *)self.updatedContentSignal sendNext:nil];
    }
}

#pragma mark 获取联系人分组
- (void)fetchGroups
{
    NSError *error = nil;
    if (![self.fetchedGroupsResultsController performFetch:&error]) {
        NSLog(@"获取联系人分组失败");
    }
    else {
        NSArray *dataArray = [self.fetchedGroupsResultsController fetchedObjects];
        NSLog(@"组个数 = %d", dataArray.count);
        if (dataArray.count > 0) {
            self.groupModel = [[NSMutableArray alloc] initWithCapacity:dataArray.count];
            for (XMPPGroupCoreDataStorageObject *group in dataArray) {
                NSMutableDictionary *groupDic = [[NSMutableDictionary alloc] init];
                NSMutableArray *userArray = [[NSMutableArray alloc] init];
                for (XMPPUserCoreDataStorageObject *user in group.users) {
                    [userArray addObject:user];
                }
                [groupDic addEntriesFromDictionary:@{group.name : userArray}];
                [self.groupModel addObject:groupDic];
            }
        }
        [(RACSubject *)self.updatedContentSignal sendNext:nil];
    }
}

#pragma mark 解除好友关系
- (BOOL)deleteUser:(XMPPUserCoreDataStorageObject *)user
{
    if (user) {
        NSManagedObjectContext *context = [XMPPManager sharedManager].managedObjectContext_roster;
        [context deleteObject:user];
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"解除好友关系出错 %@, %@", error, [error userInfo]);
            return NO;
        }
    }
    return YES;
}


#pragma mark 判断用户是否存在联系人列表中
- (BOOL)isExistInContactsList:(NSString *)userJid
{
    for (XMPPUserCoreDataStorageObject *user in self.contactModel) {
        
        if ([user.jidStr isEqualToString:userJid]) {
            if ([user.subscription isEqualToString:@"none"]) {
                NSLog(@"非好友");
                return NO;
            }
            return YES;
        }
    }
    return NO;
}




#pragma mark 获取双向好友
- (void)pickBothFriendFromRosterArray:(NSArray *)dataArray
{
    NSMutableArray *newDataArray = [NSMutableArray arrayWithCapacity:dataArray.count];
    for (XMPPUserCoreDataStorageObject *user in dataArray) {
        if (([user.subscription isEqualToString:@"both"] || [user.subscription isEqualToString:@"to"])) {
            [newDataArray addObject:user];
        }
    }
    
    // 设置为已互相添加好友及邀请对方好友
    [self updateContactModelWithDataArray:newDataArray];
}


#pragma mark 设置为以互相添加好友
- (void)updateContactModelWithDataArray:(NSArray *)dataArray
{
    NSLog(@"获取双向好友和加对方好友...");
    if (dataArray.count > 0) {
        for (XMPPUserCoreDataStorageObject *user in dataArray) {
            NSLog(@"user = %@, group = %@", user.displayName, user.groups);
        }
        
        if (!self.contactModel) {
            self.contactModel = [[NSMutableArray alloc] initWithArray:dataArray];
        } else {
            [self.contactModel setArray:dataArray];
        }
    }
    else {
        NSLog(@"没有相互好友");
        self.contactModel = [NSMutableArray array];
    }
}


#pragma mark 设置谓词来搜索联系人
- (void)setPredicateForSearchContacts:(NSString *)filterName
{
    NSPredicate *filterPredicate1 = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"jidStr CONTAINS '%@'", filterName]];
    NSArray *subPredicates = [NSArray arrayWithObjects:filterPredicate1, nil];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    [self.fetchedUsersSearchResultsController.fetchRequest setPredicate:predicate];
}



#pragma mark 设置谓词来获取联系人
- (void)setPredicateForFetchContacts
{
    NSPredicate *filterPredicate1 = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"streamBareJidStr == '%@'", [XMPPManager sharedManager].myJID.bare]];
    NSPredicate *filterPredicate2 = [NSPredicate predicateWithFormat:@"subscription == 'both'"];
    NSArray *subPredicates = [NSArray arrayWithObjects:filterPredicate1, filterPredicate2, nil];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    [self.fetchedUsersResultsController.fetchRequest setPredicate:predicate];
}

#pragma mark NSFetchSearchResultsController
- (NSFetchedResultsController *)fetchedUsersSearchResultsController
{
    NSLog(@"搜索好友...");
    if (!_fetchedUsersSearchResultsController) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:self.model];
        
        NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
        NSArray *sortDescriptors = @[sd1];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setFetchBatchSize:10];
        
        _fetchedUsersSearchResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                             managedObjectContext:self.model sectionNameKeyPath:nil cacheName:nil];
        [_fetchedUsersSearchResultsController setDelegate:self];
    }
    return _fetchedUsersSearchResultsController;
}



#pragma mark NSFetchResultsController
- (NSFetchedResultsController *)fetchedUsersResultsController
{
    NSLog(@"获取好友...");
    if (!_fetchedUsersResultsController) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:self.model];
        
        NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
        NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
        NSArray *sortDescriptors = @[sd1, sd2];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setFetchBatchSize:10];
        
        _fetchedUsersResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                             managedObjectContext:self.model sectionNameKeyPath:@"sectionNum" cacheName:nil];
        [_fetchedUsersResultsController setDelegate:self];
    }
    return _fetchedUsersResultsController;
}

#pragma mark 获取用户分组
- (NSFetchedResultsController *)fetchedGroupsResultsController
{
    NSLog(@"获取好友分组...");
    if (!_fetchedGroupsResultsController) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPGroupCoreDataStorageObject" inManagedObjectContext:self.model];
        
        NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd2, nil];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setFetchBatchSize:10];
        
        _fetchedGroupsResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.model sectionNameKeyPath:nil cacheName:nil];
        [_fetchedGroupsResultsController setDelegate:self];
        
    }
    return _fetchedGroupsResultsController;
}


#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    //[self fetchGroups];
    [self fetchUsers];
    [self fetchInviteList];
    [(RACSubject *)self.updatedContentSignal sendNext:nil];
}



#pragma mark 判断邀请人是否已经在邀请数组中
- (BOOL)isExistedInInviteContactsModel:(NSMutableArray *)inviteContactsArray toFrom:(NSString *)from
{
//    for (NSString *contact in inviteContactsArray) {
//        if ([contact isEqualToString:from]) {
//            return YES;
//        }
//    }
    
    for (FriendInviteMsgModel * friendMsg in inviteContactsArray) {
        if ([friendMsg.userJid isEqualToString:from]) {
            return YES;
        }
    }
    return NO;
}


/////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark DataSource
/////////////////////////////////////////////////////////////////////////////////////////////////


#pragma mark 用户分组数
- (NSInteger)numberOfSections
{
    NSLog(@"用户分组数:%lu", (unsigned long)[self.groupModel count]);
    return [self.groupModel count];
}


#pragma mark 每个分组的用户数
- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    if (section < [self.groupModel count]) {
        NSDictionary *userDic = [self.groupModel objectAtIndex:section];
        NSArray *userArray = [userDic valueForKey:[userDic allKeys][0]];
        
        NSLog(@"每个分组的用户数:%lu", (unsigned long)userArray.count);
        return userArray.count;
    }
    return 0;
}


#pragma mark 返回section对应用户组
- (id)objectAtSection:(NSInteger)section
{
    NSDictionary *groupDic = [self.groupModel objectAtIndex:section];
    return groupDic;
}

// 分组显示全部好友
- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *userDic = [self.groupModel objectAtIndex:indexPath.section];
    XMPPUserCoreDataStorageObject *user = [userDic valueForKey:[userDic allKeys][0]][indexPath.row];
    
    return user;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Search DataSource
///////////////////////////////////////////////////////////////////////////////////////////////////


#pragma mark 搜索群组
- (NSInteger)numberOfSearchItemsInSection:(NSInteger)section
{
    return [self.searchContactsModel count];
}


- (id)objectAtSearchIndexPath:(NSIndexPath *)indexPath
{
    return [self.searchContactsModel objectAtIndex:indexPath.row];
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark 好友邀请
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



- (NSInteger)numberOfNewItemsInSection:(NSInteger)section
{
    return self.inviteContactsModel.count;
}

- (id)objectAtNewIndexPath:(NSIndexPath *)indexPath
{
    return [self.inviteContactsModel objectAtIndex:indexPath.row];
}

#pragma mark --删除已添加的用户列表。


#pragma mark 重置未添加新的好友数目
- (void)resetUnsubscribeContactCount
{
    NSLog(@"重置未添加好友数目...");
    self.unsubscribedCountNum = @0;
    
    for (FriendInviteMsgModel * friendMsgModel in self.inviteContactsModel) {
        friendMsgModel.isRead = @"1";
    }
    
    NSError * error;
    if (![self.friendInviteContext save:&error]) {
        //重置未读的加好友的同伙列表
        NSLog(@"%s,重置未读的未加好友的数量失败",__FUNCTION__);
    }
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark 邀请好友加入群组
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



- (NSInteger)numberOfInviteUsersInSection:(NSInteger)section
{
    return self.contactModel.count;
}

- (id)objectAtInviteUsersIndexPath:(NSIndexPath *)indexPath
{
    XMPPUserCoreDataStorageObject *user = [self.contactModel objectAtIndex:indexPath.row];
    
    return user;
}



//////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStreamDelegate
//////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@"ContactsViewModel接收到IQ包%@", iq);
    
    // 判断是否为搜索联系人消息
    if ([iq isSearchContacts]) {
        self.searchContactsModel = [[NSMutableArray alloc] init];
        
        for (NSXMLElement *element in iq.children) {
            for (NSXMLElement *x in element.children) {
                for (NSXMLElement *item in x.children) {
                    if ([item.name isEqualToString:@"item"]) {
                        for (NSXMLElement *field in item.children) {
                            if ([field.attributesAsDictionary[@"var"] isEqualToString:@"Username"]) {
                                for (NSXMLElement *value in field.children) {
                                    NSString *userJID = [NSString stringWithFormat:@"%@", value.children[0]];
                                    [self.searchContactsModel addObject:userJID];
                                }
                            }
                        }
                    }
                }
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SEARCH_CONTACTS_RELOAD_DATA" object:self userInfo:nil];
        return YES;
    }
    
    return YES;
}

//- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
//{
//    NSLog(@"ContactsViewModel接收到Presence %@", [presence description]);
////==//
//    // 接收到好友请求
//    if ([[presence type] isEqualToString:@"subscribe"]) {
//        NSString *from = [NSString stringWithFormat:@"%@", [presence from]];
//        
//        NSLog(@"%@申请加您为好友", from);
//        
//        
//        
//        if (![self isExistedInInviteContactsModel:self.inviteContactsModel toFrom:from]) {
//            [self.inviteContactsModel addObject:from];
//            self.unsubscribedCountNum = [NSNumber numberWithInt:self.unsubscribedCountNum.intValue + 1];
//        }
//        //TODO: 李小涛，这里原来是注释的部分。
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"FRIENDS_INVITE_SUBSCRIBED_COUNT_NUM" object:self userInfo:@{@"scribeNum" : self.unsubscribedCountNum}];
////        [[NSNotificationCenter defaultCenter] postNotificationName:@"FRIENDS_INVITE_RELOAD_DATA" object:self userInfo:nil];
//    } else if ([[presence type] isEqualToString:@"unsubscribe"]) {
//        NSLog(@"对方请求解除好友关系...");
//        
//    }
//}




- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"ContactsViewModel接收到Presence %@", [presence description]);
    //==//
    // 接收到好友请求
    if ([[presence type] isEqualToString:@"subscribe"]) {
        NSString *from = [NSString stringWithFormat:@"%@", [presence from]];
        
        NSLog(@"%@申请加您为好友", from);
        
        
        if (![self isExistedInInviteContactsModel:self.inviteContactsModel toFrom:from]) {
            
            FriendInviteMsgModel * friendMsg = [NSEntityDescription insertNewObjectForEntityForName:@"FriendInviteMsgModel" inManagedObjectContext:self.friendInviteContext];
            friendMsg.userJid = from;
            friendMsg.isRead = @"0";
            friendMsg.isInvited = @"1";
            friendMsg.isWaitingAccept = @"0";
            friendMsg.keyId = [NSString stringWithFormat:@"%zi",self.inviteContactsModel.count + 1];
            [self.inviteContactsModel addObject:friendMsg];
            
            NSError * error = nil;
            if (![self.friendInviteContext save:&error]) {
                NSLog(@"好友邀请，保存失败了");
            }
            self.unsubscribedCountNum = [NSNumber numberWithInt:self.unsubscribedCountNum.intValue + 1];
            //TODO: 李小涛，这里原来是注释的部分。
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FRIENDS_INVITE_SUBSCRIBED_COUNT_NUM" object:self userInfo:@{@"scribeNum" : self.unsubscribedCountNum}];

        }else{
            
            for (FriendInviteMsgModel * model in self.inviteContactsModel) {
                if ([model.userJid isEqualToString:from]&& [model.isWaitingAccept isEqualToString:@"1"]) {
                    [self deleteInviteUser:model.userJid];
                }
            }
        }
        
        
    } else if ([[presence type] isEqualToString:@"unsubscribe"]) {
        NSLog(@"对方请求解除好友关系...");
        NSString *from = [NSString stringWithFormat:@"%@", [presence from]];
        for (FriendInviteMsgModel * model in self.inviteContactsModel) {
            if ([model.userJid isEqualToString:from]&& [model.isWaitingAccept isEqualToString:@"1"]) {
                [self deleteInviteUser:model.userJid];
            }
        }
    }
    
    
    //用户接受了邀请，需要刷新
    [self fetchUsers];
}



#pragma mark 获取用户名称
- (NSString *)getName:(NSString *)JID
{
    NSString *name = [NSString stringWithFormat:@"%@", [JID componentsSeparatedByString:@"@"][0]];
    return name;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item
{
    NSLog(@"ContactsViewModel接收到Roster Item:%@", item);
    
    NSXMLElement *copyItem = [item copy];
    NSString *subscription = [copyItem attributeStringValueForName:@"subscription"];
    
    // <item jid="uuu@192.168.0.84" subscription="both"></item>
    if ([subscription isEqualToString:@"both"]) {
        
    }
    else if ([subscription isEqualToString:@"remove"]) {
        
    }
}

- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    
    NSLog(@"ContactsViewModel在线订阅请求, %@", [presence description]);
    
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - XMPPMUC Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *) roomJID didReceiveInvitation:(XMPPMessage *)message
{
    NSLog(@"ContactsViewModel XMPPMUC Delegate 接收群组:%@到邀请:%@...", roomJID, message);
    if ([message isChatRoomInvite]) {
        NSString *roomJid = message.attributesAsDictionary[@"from"];
        NSString *fromJid;
        NSString *reasonStr;
        
        for (NSXMLElement *x in message.children) {
            if ([x.xmlns isEqualToString:@"http://jabber.org/protocol/muc#user"]) {
                for (NSXMLElement *invite in x.children) {
                    fromJid = [NSString stringWithFormat:@"%@", invite.attributesAsDictionary[@"from"]];
                    for (NSXMLElement *reason in invite.children) {
                        reasonStr = [NSString stringWithFormat:@"%@", reason.stringValue];
                    }
                }
            }
        }
        
        XMPPJID *jid = [XMPPJID jidWithString:roomJid];
        
        UIAlertView *alterView = [[UIAlertView alloc] initWithTitle:@"群组邀请" message:[NSString stringWithFormat:@"%@邀请您加入群组：%@\n原因：%@", [self getName:fromJid], [self getName:roomJid], reasonStr] delegate:self cancelButtonTitle:@"拒绝" otherButtonTitles:@"同意", nil];
        [alterView show];
        
        [[alterView rac_buttonClickedSignal] subscribeNext:^(NSNumber *x) {
            if ([x intValue] == 0) {
                NSLog(@"拒绝加入群组: %@", roomJid);
                
                [[XMPPRoomManager sharedManager] rejectInviteRoom:jid withReason:@"I'm Busy now."];
            }
            else {
                NSLog(@"同意加入群组, 申请发言权: %@", roomJid);
                
                [[XMPPRoomManager sharedManager] applyVoiceFromRoom:roomJid];
                
            }
        }];
    }
}


- (void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *) roomJID didReceiveInvitationDecline:(XMPPMessage *)message
{
    NSLog(@"ContactsViewModel XMPPMUC Delegate 接收群组:%@到邀请拒绝:%@...", roomJID, message);
}

#pragma mark --fetchInviteListResultsController

- (NSFetchedResultsController *)fetchInviteListResultsController{
    
    if (!_fetchInviteListResultsController) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"FriendInviteMsgModel" inManagedObjectContext:self.friendInviteContext];
        //TODO: sortDescriptor是必须要有的。
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"keyId" ascending:YES];       // 按时间排序
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd, nil];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        
        
        _fetchInviteListResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.friendInviteContext sectionNameKeyPath:nil cacheName:nil];
        [_fetchInviteListResultsController setDelegate:self];
    }
    return _fetchInviteListResultsController;
    
}

#pragma mark--获取到本地的被邀请以及主动邀请的列表。
- (void)fetchInviteList{
    
    NSError *error = nil;
    if (![self.fetchInviteListResultsController performFetch:&error]) {
        NSLog(@"查询失败，失败原因:%@",error);
    }else{
        NSArray * dataArray = [self.fetchInviteListResultsController fetchedObjects];
        
        [self.inviteContactsModel removeAllObjects];

        if (dataArray.count > 0) {
            if (!self.inviteContactsModel) {
                self.inviteContactsModel = [[NSMutableArray alloc]initWithArray:self.fetchInviteListResultsController.fetchedObjects];
            }else{
                [self.inviteContactsModel setArray:dataArray];
            }
        }
        
        for (FriendInviteMsgModel * friendInviteModel in dataArray) {
            if ([friendInviteModel.isRead isEqualToString:@"0"] && [friendInviteModel.isWaitingAccept isEqualToString:@"0"]) {
                NSLog(@"!!!!=================%@==============!!!!!",friendInviteModel.userJid);
                self.unsubscribedCountNum = [NSNumber numberWithInt:self.unsubscribedCountNum.intValue + 1];
            }
        }
        
        [(RACSubject *)self.updatedContentSignal sendNext:nil];
   
    }
}

-(void)deleteInviteUser:(NSString *)userJid{
    
    NSPredicate *filterPredicate1 = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"userJid == '%@'", userJid]];
    NSArray *subPredicates = [NSArray arrayWithObjects:filterPredicate1,nil];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    [self.fetchInviteListResultsController.fetchRequest setPredicate:predicate];
        
    NSError *error = nil;
    if (![self.fetchInviteListResultsController performFetch:&error]) {
        NSLog(@"获取联系人列表失败");
    }
    else {
        NSArray * dataArray = [self.fetchInviteListResultsController fetchedObjects];
        FriendInviteMsgModel * friendModel = [dataArray firstObject];
        
        [self.friendInviteContext deleteObject:friendModel];
        NSError * error = nil;
        
        if (![self.friendInviteContext save:&error]) {
            NSLog(@"删除失败");
        }
    }

}





@end
