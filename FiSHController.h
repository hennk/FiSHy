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
#import "Chat Core/MVChatPluginManager.h"

#import "FiSHKeyExchanger.h";

@class FiSHBlowfish;
@class FiSHEncryptionPrefs;

/// Central controller. Reacts to incoming and outgoing messages, and uses the other classes to encrypt/decrypt these.
@interface FiSHController : NSObject <MVChatPlugin, FiSHKeyExchangerDelegate>
{
   FiSHKeyExchanger *keyExchanger_;
   FiSHBlowfish *blowFisher_;
   
   FiSHEncryptionPrefs *encPrefs_;
   
   NSMutableDictionary *urlToConnectionCache_;
}
@end
