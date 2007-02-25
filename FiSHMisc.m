//
//  FiSHMisc.m
//  FiSHy
//
//  Created by Henning Kiel on 25.02.07.
//  Copyright 2007 Henning Kiel. All rights reserved.
//

#import "FiSHMisc.h"

#import "Controllers/JVChatWindowController.h"
#import "Chat Core/MVChatUser.h"
#import "Chat Core/MVChatRoom.h"
#import "Chat Core/MVChatConnection.h"


JVDirectChatPanel *FiSHDirectChatPanelForChatViewController(id <JVChatViewController> chatViewController)
{
   if (![chatViewController isKindOfClass:NSClassFromString(@"JVDirectChatPanel")])
      return nil;
   else
      return (JVDirectChatPanel *)chatViewController;
}

NSString *FiSHNameForChatObject(id chatObject)
{
   if ([chatObject isKindOfClass:NSClassFromString(@"MVChatUser")])
      return [(MVChatUser *)chatObject nickname];
   else if ([chatObject isKindOfClass:NSClassFromString(@"MVChatRoom")])
      return [(MVChatRoom *)chatObject name];
   else
      return nil;
}

BOOL FiSHIsIRCConnection(id connection)
{
   return [connection isKindOfClass:NSClassFromString(@"MVIRCChatConnection")];
}
