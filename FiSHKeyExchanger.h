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


@protocol FiSHKeyExchangerDelegate;


@interface FiSHKeyExchanger : NSObject
{
   NSMutableDictionary *temporaryKeyExchangeInfos_;
   NSRecursiveLock *temporaryKeyExchangeInfosLock_;
   
   id <FiSHKeyExchangerDelegate> delegate_;
}

- (id)initWithDelegate:(id <FiSHKeyExchangerDelegate>)delegate;

- (void)requestTemporarySecretFor:(NSString *)nickname onConnection:(id)connection;

- (BOOL)processPrivateMessageAsData:(NSData *)message from:(NSString *)sender on:(id)connection;
@end


@protocol FiSHKeyExchangerDelegate
- (void)sendPrivateMessage:(NSString *)message to:(NSString *)receiver on:(id)connection;
- (void)outputStatusInformation:(NSString *)statusInfo forContext:(NSString *)chatContext on:(id)connection;
// TODO: Call the following for unsuccesfully exchanges, too.
- (void)keyExchanger:(FiSHKeyExchanger *)keyExchanger finishedKeyExchangeFor:(NSString *)nickname onConnection:(id)connection succesfully:(BOOL)succesfully;
@end
