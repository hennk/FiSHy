//
//  FiSHEncryptionPrefs.m
//  FiSHy
//
//  Created by Henning Kiel on 24.02.07.
//  Copyright 2007 Henning Kiel. All rights reserved.
//

#import "FiSHEncryptionPrefs.h"


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
