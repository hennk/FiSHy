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

#import "FiSHEncryptionPrefs.h"


@interface FiSHEncryptionPrefs (FiSHEncryptionPrefs_Private)
- (void) removeTemporaryPreferenceForService:(NSString *)service account:(NSString *)account;
@end

@implementation FiSHEncryptionPrefs
+ (void) initialize;
{
   [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:FiSHEncPrefAvoidEncrypted] forKey:@"FiSHyEncryptionDefaultPreference"]];
}

- (id) init;
{
   if ((self = [super init]))
   {
      NSDictionary *chatEncryptionPreferences = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"FiSHyEncryptionPreferences"];
      if (chatEncryptionPreferences)
         chatEncryptionPreferences_ = [chatEncryptionPreferences mutableCopy];
      else
         chatEncryptionPreferences_ = [[NSMutableDictionary alloc] init];
      
      temporarychatEncryptionPreferences_ = [[NSMutableDictionary alloc] init];
      
      defaultPref_ = [[NSUserDefaults standardUserDefaults] integerForKey:@"FiSHyEncryptionDefaultPreference"];
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillQuit:) name:NSApplicationWillTerminateNotification object:nil];
   }
   return self;
}

- (void) dealloc;
{
   [temporarychatEncryptionPreferences_ release];
   [chatEncryptionPreferences_ release];
   
   [super dealloc];
}

- (void) applicationWillQuit:(NSNotification *)aNote;
{
   [[NSUserDefaults standardUserDefaults] setInteger:defaultPref_ forKey:@"FiSHyEncryptionDefaultPreference"];
   [[NSUserDefaults standardUserDefaults] setObject:chatEncryptionPreferences_ forKey:@"FiSHyEncryptionPreferences"];
   
   [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (FiSHEncPrefKey) preferenceForService:(NSString *)serviceName account:(NSString *)accountName;
{
   // TODO: Handle service.
   
   // First look if we have a temporary pref. If not, look in the permanent prefs. If still nothing, return the default pref.
   NSNumber *result = [temporarychatEncryptionPreferences_ objectForKey:accountName];
   if (!result)
      result = [chatEncryptionPreferences_ objectForKey:accountName];
   
   if (result)
      return [result intValue];
   else
      return defaultPref_;
}

- (void) setPreference:(FiSHEncPrefKey)pref forService:(NSString *)serviceName account:(NSString *)accountName;
{
   // Remove any temporary preference we might have.
   [self removeTemporaryPreferenceForService:serviceName account:accountName];
   
   // TODO: Handle service.
   [chatEncryptionPreferences_ setObject:[NSNumber numberWithInt:pref] forKey:accountName];
}

- (void) setTemporaryPreference:(FiSHEncPrefKey)pref forService:(NSString *)serviceName account:(NSString *)accountName;
{
   // TODO: Handle service.
   [temporarychatEncryptionPreferences_ setObject:[NSNumber numberWithInt:pref] forKey:accountName];
}

- (void) setDefaultPreference:(FiSHEncPrefKey)defPref;
{
}

@end

@implementation FiSHEncryptionPrefs (FiSHEncryptionPrefs_Private)
- (void) removeTemporaryPreferenceForService:(NSString *)service account:(NSString *)account;
{
   [temporarychatEncryptionPreferences_ removeObjectForKey:account];
}
@end
