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
