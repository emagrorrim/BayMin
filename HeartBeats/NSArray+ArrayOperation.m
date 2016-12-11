//
//  Copyright © 2016 Christian Roman. All rights reserved.
//

#import "NSArray+ArrayOperation.h"

@implementation NSArray (ArrayOperation)

- (NSArray *)reverse {
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
  NSEnumerator *enumerator = [self reverseObjectEnumerator];
  for (id element in enumerator) {
    [array addObject:element];
  }
  return array;
}

@end
