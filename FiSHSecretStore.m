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

#import "FiSHSecretStore.h"

#import <Security/Security.h>


FiSHSecretStore *sharedSecretStore = nil;


@implementation FiSHSecretStore
#define FiSHStringByteLength(a) (( [a UTF8String] ? strlen( [a UTF8String] ) : 0 ))

+ (FiSHSecretStore *)sharedSecretStore;
{
   if (!sharedSecretStore)
   {
      sharedSecretStore = [[FiSHSecretStore alloc] init];
   }
   return sharedSecretStore;
}

- (id)init;
{
   if ((self = [super init]))
   {
      secretsCache_ = [[NSMutableDictionary alloc] init];
   }
   return self;
}

- (void)dealloc;
{
   [secretsCache_ release];

   [super dealloc];
}

/// Adds or updates the secret used to communicate with accountName on serviceName to the default Keychain.
/**
  If isTemporary is set, the secret won't be saved in the Keychain. Use this for keys from automatic key exchanges in queries, for example.
 */
- (BOOL)storeSecret:(NSString *)secret forService:(NSString *)serviceName account:(NSString *)accountName isTemporary:(BOOL)isTemporary;
{
   serviceName = [serviceName lowercaseString];
   accountName = [accountName lowercaseString];
   
   if (isTemporary)
   {
      // If no service is specified, place it at the top level of the secrets cache. Otherwise choose the sub-dict for the specific service.
      NSMutableDictionary *secretsForService;
      if (!serviceName)
         secretsForService = secretsCache_;
      else
      {
         secretsForService = [secretsCache_ objectForKey:serviceName];
         if (!secretsForService)
         {
            secretsForService = [NSMutableDictionary dictionary];
            [secretsCache_ setObject:secretsForService forKey:serviceName];
         }
      }
      
      [secretsForService setObject:secret forKey:accountName];
      
      return YES;
   } else
   {
      // The secret is not temporary, so delete any prior temporary secrets for this connection/nick
      NSMutableDictionary *secretsForService;
      if (!serviceName)
         secretsForService = secretsCache_;
      else
      {
         secretsForService = [secretsCache_ objectForKey:serviceName];
         if (!secretsForService)
         {
            secretsForService = [NSMutableDictionary dictionary];
            [secretsCache_ setObject:secretsForService forKey:serviceName];
         }
      }
      [secretsForService removeObjectForKey:accountName];
   }
   
   OSStatus status;
   SecKeychainItemRef itemRef = NULL;
   unsigned long secretInKeychainLength = 0;
   void *secretInKeychain = NULL;
   status = SecKeychainFindGenericPassword(NULL,
                                           FiSHStringByteLength(serviceName),
                                           [serviceName UTF8String],
                                           FiSHStringByteLength(accountName),
                                           [accountName UTF8String],
                                           &secretInKeychainLength,
                                           &secretInKeychain,
                                           &itemRef);
	SecKeychainItemFreeContent(NULL, secretInKeychain); // We are not interested in the old secret, so free it directly.
   if (status == noErr)
   {
      // We already have a key for the specific remote party saved in Keychain, so just update the key.
      // Code more or less copied from file:///Developer/ADC%20Reference%20Library/documentation/Security/Conceptual/keychainServConcepts/index.html
      SecKeychainAttribute attrs[] = {
      { kSecAccountItemAttr, FiSHStringByteLength(accountName), (void *)[accountName UTF8String] },
      { kSecServiceItemAttr, FiSHStringByteLength(serviceName), (void *)[serviceName UTF8String] }
      };
      const SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]), attrs };
      status = SecKeychainItemModifyAttributesAndData(itemRef,
                                                      &attributes,
                                                      FiSHStringByteLength(secret),
                                                      [secret UTF8String]);
      CFRelease(itemRef);
   } else if (status == errSecItemNotFound)
   {
      // Nothing saved in Keychain yet for this remote party, so create a new entry.
      status = SecKeychainAddGenericPassword(NULL,
                                             FiSHStringByteLength(serviceName),
                                             [serviceName UTF8String],
                                             FiSHStringByteLength(accountName),
                                             [accountName UTF8String],
                                             FiSHStringByteLength(secret),
                                             [secret UTF8String],
                                             NULL);
   }
   
   // TODO: Securely free the NSStrings for keys.
   
   if (status != noErr)
   {
      // Something went wrong looking for/chaning/adding an entry in Keychain, just bail out.
      NSLog(@"Can't access Keychain.");
   }
   
   return (status == noErr);
}

/// Returns the secret used to communicate with accountName on serviceName from the default Keychain, nil if no secret is stored currently.
- (NSString *)secretForService:(NSString *)serviceName account:(NSString *)accountName;
{
   NSString *secret;
   
   serviceName = [serviceName lowercaseString];
   accountName = [accountName lowercaseString];
   
   // Try first the cache. If the cache doesn't contain the requested secret, try the keychain.
   // If no serviceName was specified, take the secret from the top-level, otherwise dive into one of the sub-dicts.
   NSMutableDictionary *secretsForService;
   if (!serviceName)
      secretsForService = secretsCache_;
   else
      secretsForService = [secretsCache_ objectForKey:serviceName];
   secret = [secretsForService objectForKey:accountName];
   if (secret)
      return secret;

   // Nothing found in cache, search in Keychain.
   OSStatus status;
   SecKeychainItemRef itemRef;
   unsigned long secretInKeychainLength = 0;
   void *secretInKeychain = NULL;
   status = SecKeychainFindGenericPassword(NULL,
                                           FiSHStringByteLength(serviceName),
                                           [serviceName UTF8String],
                                           FiSHStringByteLength(accountName),
                                           [accountName UTF8String],
                                           &secretInKeychainLength,
                                           &secretInKeychain,
                                           &itemRef);
   if (status != noErr)
   {
      // No key found in Keychain.
      return nil;
   }
   
   // Create an NSString from the returned cString.
   secret = [[NSString alloc] initWithBytes:secretInKeychain length:secretInKeychainLength encoding:NSUTF8StringEncoding];
   
	SecKeychainItemFreeContent(NULL, secretInKeychain); // Free the cString got from SecurityServices.
   
   // Free the itemRef to the keychain entry, and Zero all memory containing keys.
   if (itemRef)
   {
      CFRelease(itemRef);
   }
   // TODO: Securely free the NSStrings for keys.
   
   return [secret autorelease];
}

@end
