// FiSHy, a plugin for Colloquy providing Blowfish encryption.
// Copyright (C) 2007  Henning Kiel
// 
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#import "FiSHController.h"

#import "Models/JVChatMessage.h"
#import "Controllers/JVChatWindowController.h"
#import "Controllers/JVChatController.h"
#import "Panels/JVChatRoomPanel.h"
#import "Chat Core/MVChatUser.h"
#import "Chat Core/MVChatConnection.h"
#import "Models/JVChatTranscript.h"

#import "FiSHSecretStore.h"
#import "FiSHBlowfish.h"
#import "NSString+FiSHyExtensions.h"


#define FiSHYDummyConnection @"FiSHYDummyConnection"

// Notifications defined in MVChatConnection.m
//   We define these here manually to avoid importing the implementation of MVChatConnection, as the notifications in its header-file are only extern'ed.
NSString *MVChatConnectionGotPrivateMessageNotification = @"MVChatConnectionGotPrivateMessageNotification";

// Postfix of encrypted messages to mark them visibly for the user.
// TODO: Make this user-configurable.
NSString *FiSHEncryptedMessageMarker = @" :*";

// Prefix of outgoing messages which we should not encrypt.
// TODO: Make this user-configurable.
NSString *FiSHNonEncryptingPrefix = @"+p ";

// Command used to trigger an automatic key exchange. Syntax: /keyx [nick]. If no nick is given, the nick from the current query is used.
NSString *FiSHKeyExchangeCommand = @"keyx";
// Command used to set a key manually. Syntax: /setkey [#channel/nick] newkey. Contrary to keys from automated key exchange, these will be saved to Keychain. If only one argument is given, will use it as key, and will try to deduce the #channel/nick from current view's target.
NSString *FiSHSetKeyCommand = @"setkey";


@interface FiSHController (FiSHyPrivate)
@end


@implementation FiSHController
#pragma mark MVChatPlugin
- (id)initWithManager:(MVChatPluginManager *) manager;
{
   if (self = [super init])
   {
//      NSLog(@"Loading FiSHy.");
      
      keyExchanger_ = [[FiSHKeyExchanger alloc] initWithDelegate:self];
      urlToConnectionCache_ = [[NSMutableDictionary alloc] init];
      blowFisher_ = [[FiSHBlowfish alloc] init];
      
      chatEncryptionPreferences_ = [[NSMutableDictionary alloc] init];
   }
   return self;
}

- (void)dealloc;
{
   [chatEncryptionPreferences_ release];
   
   [blowFisher_ release];
   [urlToConnectionCache_ release];
   [keyExchanger_ release];
   
   [super dealloc];
}


#pragma mark FiSHKeyExchangerDelegate
- (void)sendPrivateMessage:(NSString *)message to:(NSString *)receiver on:(id)connectionURL;
{
   MVChatConnection *theConnection = [urlToConnectionCache_ objectForKey:connectionURL];
   [theConnection sendRawMessageWithFormat:[NSString stringWithFormat:@"NOTICE %@ :%@", receiver, message]];
}

- (void)outputStatusInformation:(NSString *)statusInfo forContext:(NSString *)chatContext on:(id)connectionURL;
{
   MVChatConnection *theConnection = [urlToConnectionCache_ objectForKey:connectionURL];
   MVChatUser *theUser = [theConnection chatUserWithUniqueIdentifier:chatContext];
   JVDirectChatPanel *thePanel = [[NSClassFromString(@"JVChatController") defaultController] chatViewControllerForUser:theUser 
                                                                                        ifExists:NO
                                                                                   userInitiated:NO];
   [thePanel addEventMessageToDisplay:statusInfo withName:@"KeyExchangeInfo" andAttributes:nil];
}


#pragma mark MVIRCChatConnectionPlugin

- (void) processIncomingMessageAsData:(NSMutableData *)message from:(MVChatUser *)sender to:(id)receiver isNotice:(BOOL)isNotice;
{
   // If we received a notice, it is possible, that it's a key exchange request/response. Let the FiSHKeyExchanger decide this.
   if (isNotice)
   {
      MVChatConnection *theConnection = (MVChatConnection *)[sender connection];
      [urlToConnectionCache_ setObject:theConnection forKey:[[theConnection url] absoluteString]];
      BOOL isKeyExchangeMessage = [keyExchanger_ processPrivateMessageAsData:message 
                                                                        from:[sender nickname] 
                                                                          on:[[theConnection url] absoluteString]];
      if (isKeyExchangeMessage)
      {
         [message setLength:0];
         return;
      }
   }
   
   // Get the secret for the current room/nick and connection. If we don't have one, just display the message without changes.
   // TODO: Handle service/connection correctly.
   // We have to differentiate between a message of a query or a chat room, as the method of getting at the account name is named slightly different.
   NSString *accountName = [receiver isKindOfClass:NSClassFromString(@"MVChatRoom")] ? [receiver name] : [sender nickname];
   // TODO: Handle service/connection correctly.
   NSString *secret = [[FiSHSecretStore sharedSecretStore] secretForService:nil account:accountName];
   if (!secret)
      return;
   
   // Try to decrypt the raw encrypted text.
   NSData *decryptedData = nil;
   [blowFisher_ decodeData:message intoData:&decryptedData key:secret];
   if (!decryptedData)
      return;
   // TODO: Handle cases where decryption was only partially succesfull, and display a corresponding note to the user.
   
   [message setData:decryptedData];
}

- (void) processOutgoingMessageAsData:(NSMutableData *)message to:(id)receiver;
{
//   NSString *plaintextBody = [message bodyAsPlainText];
//   
//   if ([plaintextBody hasPrefix:FiSHNonEncryptingPrefix])
//   {
//      // User override of encryption. Remove the prefix, and transmit the rest of the message unencrypted.
//      [message setBodyAsPlainText:[plaintextBody substringFromIndex:[FiSHNonEncryptingPrefix length]]];
//      return;
//   }
   
   // Check if we have a secret for the current room/nick.
   NSString *accountName = [receiver isKindOfClass:NSClassFromString(@"MVChatRoom")] ? [receiver name] : [receiver nickname];
   // TODO: Handle service/connection correctly.
   NSString *secret = [[FiSHSecretStore sharedSecretStore] secretForService:nil account:accountName];
   if (!secret)
      return;
   
   NSData *encryptedData = nil;
   [blowFisher_ encodeData:message intoData:&encryptedData key:secret];
   // TODO: Handle return value of encodeData.
   if (!encryptedData)
      return;
   
   [message setData:encryptedData];
}

#pragma mark MVChatPluginDirectChatSupport

//- (void)processIncomingMessage:(JVMutableChatMessage *)message inView:(id <JVChatViewController>)aView;
//{
//   return;
//   
//   // Neither JVMutableChatMessage nor the JVChatViewController protocol allow us to get the context of the received message (ie. the corresponding channel/query)
//   // It seems that most, if not all, views we get here are of a subclass of JVDirectChatPanel, which do allow us to get above context.
//   // So check first for the correct class-membership before proceeding.
//   if (![aView isKindOfClass:NSClassFromString(@"JVDirectChatPanel")])
//   {
//      NSLog(@"Unexpected view class encountered.");
//      return;
//   }
//   // It's now safe to typecast view, to prevent compiler-warnings later.
//   JVDirectChatPanel *view = (JVDirectChatPanel *)aView;
//   
//   NSLog(@"processIncomingMessage:%@", [message bodyAsHTML]);
//
//   // Get the secret for the current room/nick and connection. If we don't have one, just display the message without changes.
//   // DEBUG!!! Hardcoded service and account
//   // We have to differentiate between a message of a query or a chat room, as the method of getting at the account name is named slightly different.
//   NSString *accountName = [[view target] isKindOfClass:NSClassFromString(@"MVChatUser")] ? [[view target] nickname] : [[view target] name];
//   // TODO: Handle service/connection correctly.
//   NSString *secret = [[FiSHSecretStore sharedSecretStore] secretForService:nil account:accountName];
//   if (!secret)
//      return;
//
//   // Try to decrypt the raw encrypted text.
//   NSData *decryptedData = nil;
//   [blowFisher_ decodeData:[[message bodyAsPlainText] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO] 
//                    intoData:&decryptedData
//                         key:secret];
//   if (!decryptedData)
//      return;
//   // TODO: Handle cases where decryption was only partial succesfull, and display a corresponding note to the user.
//
//   NSString *decryptedMessage = [[[NSString alloc] initWithData:decryptedData encoding:[view encoding]] autorelease];
//   // Update the message with the decrypted text, marking it, so the user knows it was encrypted.
//   [message setBodyAsPlainText:[decryptedMessage stringByAppendingString:FiSHEncryptedMessageMarker]];
//}
//
//- (void)processOutgoingMessage:(JVMutableChatMessage *)message inView:(id <JVChatViewController>)aView;
//{
//   return;
//   
//   // Neither JVMutableChatMessage nor the JVChatViewController protocol allow us to get the context of the received message (ie. the corresponding channel/query)
//   // It seems that most, if not all, views we get here are of a subclass of JVDirectChatPanel, which do allow us to get above context.
//   // So check first for the correct class-membership before proceeding.
//   if (![aView isKindOfClass:NSClassFromString(@"JVDirectChatPanel")])
//   {
//      NSLog(@"Unexpected view class encountered.");
//      return;
//   }
//   // It's now safe to typecast view, to prevent compiler-warnings later.
//   JVDirectChatPanel *view = (JVDirectChatPanel *)aView;
//
//   NSLog(@"processOutgoingMessage:%@", message);
//   
//   NSString *plaintextBody = [message bodyAsPlainText];
//   
//   if ([plaintextBody hasPrefix:FiSHNonEncryptingPrefix])
//   {
//      // User override of encryption. Remove the prefix, and transmit the rest of the message unencrypted.
//      [message setBodyAsPlainText:[plaintextBody substringFromIndex:[FiSHNonEncryptingPrefix length]]];
//      return;
//   }
//   
//   // Check if we have a secret for the current room/nick.
//   NSString *accountName = [[view target] isKindOfClass:NSClassFromString(@"MVChatUser")] ? [[view target] nickname] : [[view target] name];
//   // TODO: Handle service/connection correctly.
//   NSString *secret = [[FiSHSecretStore sharedSecretStore] secretForService:nil account:accountName];
//   if (!secret)
//      return;
//   
//   NSData *encryptedData = nil;
//   [blowFisher_ encodeData:[plaintextBody dataUsingEncoding:[view encoding] allowLossyConversion:YES] intoData:&encryptedData key:secret];
//   // TODO: Handle return value of encodeData.
//   if (!encryptedData)
//      return;
//   
//   NSString *encryptedMessage = [[[NSString alloc] initWithData:encryptedData encoding:NSASCIIStringEncoding] autorelease];
//   [message setBodyAsPlainText:encryptedMessage];
//}


//#pragma mark MVChatPluginRoomSupport
//- (void) joinedRoom:(JVChatRoomPanel *) room;
//{
//   NSLog(@"joinedRoom:%@", room);
//}
   

#pragma mark Command handlers

- (BOOL)processKeyExchangeCommandWithArguments:(NSAttributedString *)arguments toConnection:(MVChatConnection *)connection inView:(id <JVChatViewController>)aView;
{
   // Neither JVMutableChatMessage nor the JVChatViewController protocol allow us to get the context of the received message (ie. the corresponding channel/query)
   // It seems that most, if not all, views we get here are of a subclass of JVDirectChatPanel, which do allow us to get above context.
   // So check first for the correct class-membership before proceeding.
   if (![aView isKindOfClass:NSClassFromString(@"JVDirectChatPanel")])
   {
      NSLog(@"Unexpected view class encountered.");
      return NO;
   }
   // It's now safe to typecast view, to prevent compiler-warnings later.
   JVDirectChatPanel *view = (JVDirectChatPanel *)aView;

   NSString *argumentString = [arguments string];
   // If no argument has been given, try to deduce it from the current view. This only works for queries, as key exchange for channels is not supported.
   if (!argumentString || [argumentString length] <= 0)
   {
      if ([[view target] isKindOfClass:NSClassFromString(@"MVChatUser")])
         argumentString = [[view target] nickname];
      else
      {
         // TODO: Put out notice to user.
         NSLog(@"No argument provided to /keyx, aborting.");
         return NO;
      }
   }
   // Check if argument is a channel-name. If so, cancel.
   if ([argumentString hasPrefix:@"#"] || [argumentString hasPrefix:@"&"])
   {
      // TODO: Put out notice to user.
      NSLog(@"Key exchange is only supported for nicknames, not for channels, aborting.");
      return NO;
   }
   
   // Everything's fine, start the key exchange.
   [urlToConnectionCache_ setObject:connection forKey:[[connection url] absoluteString]];
   [keyExchanger_ requestTemporarySecretFor:argumentString onConnection:[[connection url] absoluteString]];
   
   return YES;
}

- (BOOL)processSetKeyCommandWithArguments:(NSAttributedString *)arguments toConnection:(MVChatConnection *)connection inView:(id <JVChatViewController>)aView;
{
   NSString *argumentString = [arguments string];
   // If no argument has been given, abort.
   if (!argumentString || [argumentString length] <= 0)
   {
      // TODO: Put out notice to user.
      NSLog(@"No arguments provided to /setkey, aborting.");
      return NO;
   }

   // Neither JVMutableChatMessage nor the JVChatViewController protocol allow us to get the context of the received message (ie. the corresponding channel/query)
   // It seems that most, if not all, views we get here are of a subclass of JVDirectChatPanel, which do allow us to get above context.
   // So check first for the correct class-membership before proceeding.
   if (![aView isKindOfClass:NSClassFromString(@"JVDirectChatPanel")])
   {
      NSLog(@"Unexpected view class encountered.");
      return NO;
   }
   // It's now safe to typecast view, to prevent compiler-warnings later.
   JVDirectChatPanel *view = (JVDirectChatPanel *)aView;
   
   // Check number of arguments. If two, proceed. If one, try to deduce target by current view's target. If anything else, abort.
   NSArray *argumentList = [[arguments string] FiSH_arguments];
   NSString *secret = nil;
   NSString *account = nil;
   if ([argumentList count] == 1)
   {
      // If only one argument has been given, use that as secret, and try to deduce the account from the current view.
      if ([[view target] isKindOfClass:NSClassFromString(@"MVChatUser")])
         account = [[view target] nickname];
      else if ([[view target] isKindOfClass:NSClassFromString(@"MVChatRoom")])
         account = [[view target] name];
      else {
         // TODO: Put out notice to user.
         NSLog(@"SetKey expects exactly 2 arguments, aborting.");
         return NO;
      }
      secret = [argumentList objectAtIndex:0];
   } else if ([argumentList count] == 2)
   {
      secret = [argumentList objectAtIndex:1];
      account = [argumentList objectAtIndex:0];
   } else
   {
      // TODO: Put out notice to user.
      NSLog(@"SetKey expects exactly 2 arguments, aborting.");
      return NO;
   }
   
   // Everything's fine, set the key.
   // TODO: Handle service/connection correctly.
   [[FiSHSecretStore sharedSecretStore] storeSecret:secret forService:nil account:account isTemporary:NO];
   
   return YES;
}

#pragma mark MVChatPluginCommandSupport

- (BOOL)processUserCommand:(NSString *) command withArguments:(NSAttributedString *) arguments toConnection:(MVChatConnection *) connection inView:(id <JVChatViewController>)aView;
{
   // Neither JVMutableChatMessage nor the JVChatViewController protocol allow us to get the context of the received message (ie. the corresponding channel/query)
   // It seems that most, if not all, views we get here are of a subclass of JVDirectChatPanel, which do allow us to get above context.
   // So check first for the correct class-membership before proceeding.
   if (![aView isKindOfClass:NSClassFromString(@"JVDirectChatPanel")])
   {
      NSLog(@"Unexpected view class encountered.");
      return NO;
   }
   // It's now safe to typecast view, to prevent compiler-warnings later.
   JVDirectChatPanel *view = (JVDirectChatPanel *)aView;
   
   // Check for correct command string.
   if ([command isEqualToString:FiSHKeyExchangeCommand])
      return [self processKeyExchangeCommandWithArguments:arguments toConnection:connection inView:view];
   if ([command isEqualToString:FiSHSetKeyCommand])
      return [self processSetKeyCommandWithArguments:arguments toConnection:connection inView:view];
   
   return NO;
}


@end

@implementation FiSHController (FiSHyPrivate)
@end
