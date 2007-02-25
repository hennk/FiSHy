//
//  FiSHMisc.h
//  FiSHy
//
//  Created by Henning Kiel on 25.02.07.
//  Copyright 2007 Henning Kiel. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JVDirectChatPanel;
@class MVChatConnection;
@protocol JVChatViewController;

/// Checks if chatViewController is a JVDirectChatPanel or a subclass of JVDirectChatPanel. If it is, it returns a correctly casted reference, if not, just nil.
JVDirectChatPanel *FiSHDirectChatPanelForChatViewController(id <JVChatViewController> chatViewController);

/// Returns the name for the supplied object. chatObject is either a ChatRoom or a ChatUser. Returns nil, if chatObject is not of any supported class.
NSString *FiSHNameForChatObject(id chatObject);

BOOL FiSHIsIRCConnection(MVChatConnection *connection);
