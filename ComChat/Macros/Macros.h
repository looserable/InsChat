//
//  Macros.h
//  ComChat
//
//  Created by D404 on 15/6/3.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#ifndef ComChat_Macros_h
#define ComChat_Macros_h

#if 1
#define XMPP_DOMAIN         @"localhost.localdomain"
#define XMPP_HOST_NAME      @"219.232.254.209"
//219.232.254.209

#else
#define XMPP_DOMAIN         @"127.0.0.1"
#define XMPP_HOST_NAME      @"127.0.0.1"

#endif
#define XMPP_RESOURCE       @"ComChat"

#define HTTP_FILE_SERVER_PORT   @"8888"


#define XMPP_USER_ID        @"XMPP_USER_ID"
#define XMPP_PASSWORD       @"XMPP_PASSWORD"

#define IOS8_OR_LATER	( [[[UIDevice currentDevice] systemVersion] compare:@"8.0"] != NSOrderedAscending )
#define DEVICETOKEN         @"deviceToken"
#define ICON_COUNT          @"iconCount"

#define SCREEN_WIDHT [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height

#define NOTIFICATION_DELETE_TALK @"deletetalk"


#endif