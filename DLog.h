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

#define DLog(s,...) [DLog logFile:__FILE__ lineNumber:__LINE__ format:(s),##__VA_ARGS__]
#define DFLog(s,...) [DLog logFile:__FILE__ lineNumber:__LINE__ function:(char*)__FUNCTION__ format:(s),##__VA_ARGS__]

@interface DLog : NSObject
{
}

+ (void) logFile: (char *) sourceFile lineNumber: (int) lineNumber format: (NSString *) format, ...;
+ (void) logFile: (char *) sourceFile lineNumber: (int) lineNumber function: (char *) functionName format: (NSString *) format, ...;
+ (void) setLogOn: (BOOL) logOn;

@end