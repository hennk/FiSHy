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

#import "DLog.h"

static BOOL __DEBUG=NO;

@implementation DLog

+ (void) initialize
{
#ifdef DEBUG
   __DEBUG = YES;
#else
   char *env = getenv("DEBUG");
   env = (env == NULL ? "" : env);
   if(strcmp(env, "YES") == 0)
      __DEBUG = YES;
#endif
}

+ (void) logFile:(char *)sourceFile lineNumber:(int)lineNumber format:(NSString *)format, ...;
{
   va_list ap;
   NSString *print, *file;
   if(__DEBUG == NO)
      return;
   va_start(ap, format);
   file = [NSString stringWithCString:sourceFile];
   print = [[NSString alloc] initWithFormat:format arguments:ap];
   va_end(ap);
   
   NSLog(@"%s:%d %@", [[file lastPathComponent] UTF8String], lineNumber, print);
   
   [print release];
}

+ (void) logFile:(char *)sourceFile lineNumber:(int)lineNumber function:(char *)functionName format:(NSString *)format, ...;
{
   va_list ap;
   NSString *print, *file, *function;
   if(__DEBUG == NO)
      return;
   va_start(ap,format);
   file = [NSString stringWithCString:sourceFile];
   function = [NSString stringWithCString:functionName];
   print = [[NSString alloc] initWithFormat:format arguments:ap];
   va_end(ap);
   
   NSLog(@"%s:%d in %@ %@", [[file lastPathComponent] UTF8String], lineNumber, function, print);
   
   [print release];
}

+ (void) setLogOn: (BOOL) logOn
{
   __DEBUG=logOn;
}

@end