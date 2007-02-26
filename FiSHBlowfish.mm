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

#import "FiSHBlowfish.h"

#import "fish.h"
#include <sstream>

using namespace std;
using namespace fish;


@implementation FiSHBlowfish
- (id)init;
{
   if ((self = [super init]))
   {
      fish::init();
   }
   return self;
}

- (void)encodeData:(NSData *)inputData intoData:(NSData **)outputData key:(NSString *)theKey;
{
   string inputString((const char*)[inputData bytes], [inputData length]);
   stringstream outputStream;
   // TODO: Is utf8 the best option for the string? probably better to make sure keys are always pure ascii.
   string keyString([theKey UTF8String]);
   encode(inputString, outputStream, keyString, false);
   *outputData = [NSData dataWithBytes:outputStream.str().data() length:outputStream.str().size()];
   return;
}

- (FiSHCypherResult)decodeData:(NSData *)inputData intoData:(NSData **)outputData key:(NSString *)theKey;
{
   string inputStringTemp((const char*)[inputData bytes], [inputData length]);
   string outputStringTemp;
   // TODO: Is utf8 the best option for the string? probably better to make sure keys are always pure ascii.
   string keyString([theKey UTF8String]);
   FiSHCypherResult result;
   switch (decode(inputStringTemp, outputStringTemp, keyString))
   {
      case success: result = FiSHCypherSuccess; break;
      case cut: result = FiSHCypherTextCut; break;
      case plain_text: result = FiSHCypherPlainText; break;
      case bad_chars: result = FiSHCypherBadCharacters; break;
      default:
         // Invalid return code.
         return FiSHCypherUnknownError;
   }
   *outputData = [NSData dataWithBytes:outputStringTemp.data() length:outputStringTemp.size()];
   return result;
}

@end
