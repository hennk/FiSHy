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

#import "NSString+FiSHyExtensions.h"


@implementation NSString (FiSHyExtensions)

/// Returns components separated by spaces, but respecting quoted substrings, returning them as one component.
- (NSArray *)FiSH_arguments;
{
   NSMutableArray *result = [NSMutableArray array];
   
   NSScanner *argScanner = [NSScanner scannerWithString: self];
   NSCharacterSet *spaceCS = [NSCharacterSet whitespaceAndNewlineCharacterSet];
   NSCharacterSet *quotesCS = [NSCharacterSet characterSetWithCharactersInString: @"\""];
   
   while ([argScanner isAtEnd] == NO)
   {
      // At the beginning of a component, check if it starts with a quote.
      // This check will eat any preceding white space, as the default scanner mode is to ignore white space and newlines.
      BOOL isQuoted = [argScanner scanCharactersFromSet:quotesCS intoString:(NSString**)nil];
      if (isQuoted)
      {
         // Found quoted component.
         // Inside a quoted component, we don't want to ignore white space, as this would make it impossible to have components starting with white space.
         // So temporarily disable the scanner's default whitespace skipping.
         NSCharacterSet *savedCS = [argScanner charactersToBeSkipped];
         [argScanner setCharactersToBeSkipped:nil];
         
         // Read up to next quote.
         NSString* word = nil;
         [argScanner scanUpToCharactersFromSet:quotesCS intoString:&word];
         
         // The above read opening quote may just be the end of the string, in which case word will be nil, so check for that.
         if (word)
            [result addObject:word];
         
         // Eat the closing quote.
         [argScanner scanCharactersFromSet:quotesCS intoString:(NSString**)nil];
         
         // Reinstate eating white space
         [argScanner setCharactersToBeSkipped:savedCS];
      } else
      {
         // At the beginning of an unquoted component, read up to next white space.
         NSString* word;
         [argScanner scanUpToCharactersFromSet:spaceCS intoString:&word];
         
         [result addObject:word];
      }
   }
   
   return result;
}

@end
