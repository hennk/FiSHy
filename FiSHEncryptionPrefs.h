//
//  FiSHEncryptionPrefs.h
//  FiSHy
//
//  Created by Henning Kiel on 24.02.07.
//  Copyright 2007 Henning Kiel. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum
{
   FiSHEncPrefUndefined = 0, // Starting at 0 here, so that messages sent to nil, which return 0, match this.
   FiSHEncPrefPreferEncrypted, 
   FiSHEncPrefAvoidEncrypted
} FiSHEncPrefKey;


@interface FiSHEncryptionPrefs : NSObject
{
   NSMutableDictionary *chatEncryptionPreferences_;
   NSMutableDictionary *temporarychatEncryptionPreferences_;
   FiSHEncPrefKey defaultPref_;
}

- (FiSHEncPrefKey) preferenceForService:(NSString *)serviceName account:(NSString *)accountName;
- (void) setPreference:(FiSHEncPrefKey)pref forService:(NSString *)serviceName account:(NSString *)accountName;
- (void) setTemporaryPreference:(FiSHEncPrefKey)pref forService:(NSString *)serviceName account:(NSString *)accountName;

- (void) setDefaultPreference:(FiSHEncPrefKey)defPref;
@end
