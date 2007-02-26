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

#import "FiSHKeyExchanger.h"

#import "FiSHSecretStore.h"
#import "NSData+FiSHyExtensions.h"
#import "dh1080.h"


// Maximum amount of time we wait for a DH1080 exchange response.
#define HCKMaxTimeToWaitForDH1080Response 10.0f

// Constants used by FiSH.
NSString *HCKFiSHKeyExchangeRequest = @"DH1080_INIT ";
NSString *HCKFiSHKeyExchangeResponse = @"DH1080_FINISH ";
#define HCKFiSHMaxKeyLength 300

// Dictionary keys used to retrieve temporary key pairs
const NSString *FiSHKeyExchangeInfoDH1080Key = @"FiSHKeyExchangeDH1080Key";
const NSString *FiSHKeyExchangeInfoRemoveOldTempKeyPairTimerKey = @"FiSHKeyExchangeInfoRemoveOldTempKeyPairTimerKey";


@interface FiSHKeyExchanger (FiSHyPrivate)
- (void)addTemporaryKeyExchangeInfos:(NSValue *)dhInfos forNickname:(NSString *)nickname onConnection:(id)connection;
- (NSDictionary *)temporaryKeyExchangeInfosForNickname:(NSString *)nickname onConnection:(id)connection;
- (void)removeTemporaryKeyExchangeInfosForNickName:(NSString *)nickname onConnection:(id)connection;

- (void)handleKeyExchangeTimeoutForNickname:(NSString *)nickname onConnection:(id)connection;

- (void)handleFiSHKeyExchangeRequestFrom:(NSString *)nickname on:(id)connection withRemotePublicKeyData:(NSString *)remotePublicKeyData;
- (void)handleFiSHKeyExchangeResponseFrom:(NSString *)nickname on:(id)connection withRemotePublicKeyData:(NSString *)remotePublicKeyData;
@end

@implementation FiSHKeyExchanger
- (id)initWithDelegate:(id <FiSHKeyExchangerDelegate>)delegate;
{
   if (self = [super init])
   {
      temporaryKeyExchangeInfosLock_ = [[NSRecursiveLock alloc] init];
      temporaryKeyExchangeInfos_ = [[NSMutableDictionary alloc] init];

      delegate_ = delegate;
   }
   return self;
}

- (void)dealloc;
{
   [temporaryKeyExchangeInfosLock_ release];
   [temporaryKeyExchangeInfos_ release];
   
   [super dealloc];
}

/// Initiates a FiSH DH1080 key exchange for the specified nickname on the specified connection.
/**
  This method first generates a temporary Private/Publiy Key Pair for us, and then sends the public key to nickname on connection.
  The temporary key pair is saved, and a timer is set up to delete the key pair, if the remote party doesn't respond after a certain amount of time.
 */
- (void)requestTemporarySecretFor:(NSString *)nickname onConnection:(id)connection;
{
   // Generate the keypair we use for this exchange
   dhclass *dhKeyExchanger = new dhclass;
   if (!dhKeyExchanger->generate())
   {
      free(dhKeyExchanger);

      [delegate_ outputStatusInformation:NSLocalizedString(@"Unknown error during key exchange.", "Unknown error during key exchange")
                              forContext:nickname
                                      on:connection];
      return;
   }
   
   std::string myPubKeyTemp;
   dhKeyExchanger->get_public_key(myPubKeyTemp);
   NSString *myPubKey = [NSString stringWithUTF8String:myPubKeyTemp.c_str()];
   [delegate_ sendPrivateMessage:[NSString stringWithFormat:@"%@%@", HCKFiSHKeyExchangeRequest, myPubKey] to:nickname on:connection];
   
   [delegate_ outputStatusInformation:NSLocalizedString(@"Sending key exchange request.", "Sending key exchange request")
                           forContext:nickname
                                   on:connection];
   
   // Save the temporary key pair, and set up a timer to remove the key pair after a certain amount of time, if the remote party still has not responded.
   [self addTemporaryKeyExchangeInfos:[NSValue valueWithPointer:dhKeyExchanger] forNickname:nickname onConnection:connection];
}

/// Checks, if the private message is to initiate or respond to a key exchange.
/**
  Returns YES, if the message is about key-exchange. The delegate should then not display the raw message to the user.
  The delegate should send this message for each private message it receives, but only for messages from nicknames. We do not support keyexchange for channels.
 */
- (BOOL)processPrivateMessageAsData:(NSData *)message from:(NSString *)sender on:(id)connection
{
   // Key exchange message must be of a certain min. and max. length
   if ([message length] < 191 || [message length] > 195)
      return NO;
   
   // Handle FiSH key exchanges.
   if ([message hasStringPrefix:HCKFiSHKeyExchangeRequest encoding:NSASCIIStringEncoding])
   {
      // The notice is interpreted as a FiSH key exchange request, when its message body starts with "DH1080_INIT ".
      DLog(@"Got remote FiSH DH1080 key exchange request.");

      NSString *remotePublicKey = [[NSString alloc] initWithData:[message subDataFromIndex:[HCKFiSHKeyExchangeRequest length]] encoding:NSASCIIStringEncoding];
      
      [self handleFiSHKeyExchangeRequestFrom:sender 
                                          on:connection 
                     withRemotePublicKeyData:remotePublicKey];
      
      return YES;
   } else if ([message hasStringPrefix:HCKFiSHKeyExchangeResponse encoding:NSASCIIStringEncoding])
   {
      // The notice is interpreted as a FiSH key exchange response, when its message body starts with "DH1080_FINISH ".
      DLog(@"Got FiSH DH1080 key exchange response.");

      NSString *remotePublicKey = [[NSString alloc] initWithData:[message subDataFromIndex:[HCKFiSHKeyExchangeResponse length]] encoding:NSASCIIStringEncoding];
      
      [self handleFiSHKeyExchangeResponseFrom:sender
                                           on:connection 
                      withRemotePublicKeyData:remotePublicKey];
      return YES;
   }
   return NO;
}
@end

@implementation FiSHKeyExchanger (FiSHyPrivate)
- (void)addTemporaryKeyExchangeInfos:(NSValue *)dhInfos forNickname:(NSString *)nickname onConnection:(id)connection;
{
   [temporaryKeyExchangeInfosLock_ lock];
   
   // If we have infos for prior keyexchanges still around, make sure to remove them.
   [self removeTemporaryKeyExchangeInfosForNickName:nickname onConnection:connection];
   
   // Get the dictionary containing key pairs for the current connection.
   NSMutableDictionary *keyExchangeInfosForNicknames = [temporaryKeyExchangeInfos_ objectForKey:connection];
   if (!keyExchangeInfosForNicknames)
   {
      keyExchangeInfosForNicknames = [NSMutableDictionary dictionary];
      [temporaryKeyExchangeInfos_ setObject:keyExchangeInfosForNicknames forKey:connection];
   }
   
   // Build an invocation, which deletes the to be added key pair.
   NSMethodSignature *methodSig = [self methodSignatureForSelector:@selector(handleKeyExchangeTimeoutForNickname:onConnection:)];
   NSInvocation *removeOldTempKeyExchangeInfoInvocation = [NSInvocation invocationWithMethodSignature:methodSig];
   [removeOldTempKeyExchangeInfoInvocation setTarget:self];
   [removeOldTempKeyExchangeInfoInvocation setSelector:@selector(handleKeyExchangeTimeoutForNickname:onConnection:)];
   [removeOldTempKeyExchangeInfoInvocation setArgument:&nickname atIndex:2];
   [removeOldTempKeyExchangeInfoInvocation setArgument:&connection atIndex:3];
   
   // Create the dictionary containing the keypair, and the timer used to delete the key pair if we don't use it during a certain amount of time.
   NSDictionary *keyPair = [NSDictionary dictionaryWithObjectsAndKeys:
      dhInfos, FiSHKeyExchangeInfoDH1080Key,
      [NSTimer scheduledTimerWithTimeInterval:HCKMaxTimeToWaitForDH1080Response 
                                   invocation:removeOldTempKeyExchangeInfoInvocation 
                                      repeats:NO], FiSHKeyExchangeInfoRemoveOldTempKeyPairTimerKey,
      nil];
   
   // Add the keypair dictionary for the current nick and current connection.
   [keyExchangeInfosForNicknames setObject:keyPair forKey:nickname];
   
   [temporaryKeyExchangeInfosLock_ unlock];
}

- (NSDictionary *)temporaryKeyExchangeInfosForNickname:(NSString *)nickname onConnection:(id)connection;
{
   [temporaryKeyExchangeInfosLock_ lock];
   NSDictionary *kxInfo = [[[temporaryKeyExchangeInfos_ objectForKey:connection] objectForKey:nickname] retain];
   [temporaryKeyExchangeInfosLock_ unlock];
   
   return [kxInfo autorelease];
}

- (void)removeTemporaryKeyExchangeInfosForNickName:(NSString *)nickname onConnection:(id)connection;
{
   DLog(@"Removing temporary key exchange info for %@ on %@", nickname, connection);
   
   [temporaryKeyExchangeInfosLock_ lock];
   // First, invalidate the timer set up to remove this tempo key pair after some time has passed.
   [[[[temporaryKeyExchangeInfos_ objectForKey:connection] objectForKey:nickname] objectForKey:FiSHKeyExchangeInfoRemoveOldTempKeyPairTimerKey] invalidate];
   // Then, remove the whole entry for that key pair.
   [[temporaryKeyExchangeInfos_ objectForKey:connection] removeObjectForKey:nickname];
   [temporaryKeyExchangeInfosLock_ unlock];
}

- (void)handleKeyExchangeTimeoutForNickname:(NSString *)nickname onConnection:(id)connection;
{
   [self removeTemporaryKeyExchangeInfosForNickName:nickname onConnection:connection];
   
   [delegate_ outputStatusInformation:NSLocalizedString(@"Timed out waiting for key-exchange reply.", "Timed out waiting for key-exchange reply")
                           forContext:nickname
                                   on:connection];
}

- (void)handleFiSHKeyExchangeRequestFrom:(NSString *)nickname on:(id)connection withRemotePublicKeyData:(NSString *)remotePublicKeyData;
{
   [delegate_ outputStatusInformation:NSLocalizedString(@"Received key exchange request.", "Received key exchange request")
                           forContext:nickname
                                   on:connection];

   // Generate the keypair we use for this exchange
   dhclass dhKeyExchanger;
   if (!dhKeyExchanger.generate())
   {
      [delegate_ outputStatusInformation:NSLocalizedString(@"Unknown error during key exchange.", "Unknown error during key exchange")
                              forContext:nickname
                                      on:connection];
      return;
   }
   
   std::string myPubKeyTemp;
   dhKeyExchanger.get_public_key(myPubKeyTemp);
   NSString *myPubKey = [NSString stringWithUTF8String:myPubKeyTemp.c_str()];
   [delegate_ sendPrivateMessage:[NSString stringWithFormat:@"%@%@", HCKFiSHKeyExchangeResponse, myPubKey] to:nickname on:connection];
   
   // The remote public key has to be sent base64-encoded, so it is safe to use UTF8 here.
   std::string remotePublicKeyTemp([remotePublicKeyData UTF8String]);
   // Decode the base64 encoded received public key. It has to have a length of 135 to be valid.
   dh_base64decode(remotePublicKeyTemp);
   if (remotePublicKeyTemp.size() != 135)
   {
      [delegate_ outputStatusInformation:NSLocalizedString(@"Malformed request.", "Malformed request")
                              forContext:nickname
                                      on:connection];
      return;
   }

   // Compute the secret with our private key and the remote public key.
   dhKeyExchanger.set_her_key(remotePublicKeyTemp);
   if(!dhKeyExchanger.compute())
   {
      [delegate_ outputStatusInformation:NSLocalizedString(@"Unknown error during key exchange.", "Unknown error during key exchange")
                              forContext:nickname
                                      on:connection];
      return;
   }
   
   std::string theSecretTemp;
   dhKeyExchanger.get_secret(theSecretTemp);
   NSString *theSecret = [[[NSString alloc] initWithBytes:theSecretTemp.c_str()
                                                   length:theSecretTemp.length()
                                                 encoding:NSASCIIStringEncoding] 
      autorelease];
   
   // TODO: Handle service/connection correctly.
   [[FiSHSecretStore sharedSecretStore] storeSecret:theSecret forService:nil account:nickname isTemporary:YES];

   [delegate_ outputStatusInformation:NSLocalizedString(@"Key exchange completed.", "Key exchange completed")
                           forContext:nickname
                                   on:connection];

   [delegate_ keyExchanger:self finishedKeyExchangeFor:nickname onConnection:connection succesfully:YES];
}

- (void)handleFiSHKeyExchangeResponseFrom:(NSString *)nickname on:(id)connection withRemotePublicKeyData:(NSString *)remotePublicKeyData;
{
   NSValue *dhKeyExchangerValue = [[self temporaryKeyExchangeInfosForNickname:nickname onConnection:connection] objectForKey:FiSHKeyExchangeInfoDH1080Key];
   dhclass *dhKeyExchanger = (dhclass *)[dhKeyExchangerValue pointerValue];
   if (!dhKeyExchanger)
   {      
      // Either we timed out waiting for a response, or we never send an exchange req to that nick on that connection. Either way just ignore it.
      [delegate_ outputStatusInformation:NSLocalizedString(@"Received unrequested or too late key exchange response.", "Received unrequested or too late key exchange response")
                              forContext:nickname
                                      on:connection];
      return;
   }
   [self removeTemporaryKeyExchangeInfosForNickName:nickname onConnection:connection];
   
   // TODO: Put the following in its own method, to share code with handleFiSHKeyExchangeRequestFrom:::
   std::string remotePublicKeyTemp([remotePublicKeyData UTF8String]);
   // Decode the base64 encoded received public key. It has to have a length of 135 to be valid.
   dh_base64decode(remotePublicKeyTemp);
   if (remotePublicKeyTemp.size() != 135)
   {
      free(dhKeyExchanger);
      [delegate_ outputStatusInformation:NSLocalizedString(@"Malformed response.", "Malformed response")
                              forContext:nickname
                                      on:connection];
      return;
   }
   
   // Compute the secret with our private key and the remote public key.
   dhKeyExchanger->set_her_key(remotePublicKeyTemp);
   if (!dhKeyExchanger->compute())
   {
      free(dhKeyExchanger);
      [delegate_ outputStatusInformation:NSLocalizedString(@"Unknown error during key exchange.", "Unknown error during key exchange")
                              forContext:nickname
                                      on:connection];
      return;
   }
   
   std::string theSecretTemp;
   dhKeyExchanger->get_secret(theSecretTemp);
   NSString *theSecret = [[[NSString alloc] initWithBytes:theSecretTemp.c_str()
                                                   length:theSecretTemp.length()
                                                 encoding:NSASCIIStringEncoding] 
      autorelease];
   free(dhKeyExchanger);
   
   // TODO: Handle service/connection correctly.
   [[FiSHSecretStore sharedSecretStore] storeSecret:theSecret forService:nil account:nickname isTemporary:YES];
   
   [delegate_ outputStatusInformation:NSLocalizedString(@"Key exchange completed.", "Key exchange completed")
                           forContext:nickname
                                   on:connection];
   
   [delegate_ keyExchanger:self finishedKeyExchangeFor:nickname onConnection:connection succesfully:YES];
}


@end
