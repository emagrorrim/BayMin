//
//  Copyright © 2016 Christian Roman. All rights reserved.
//

#import "Toggle.h"

@implementation Toggle

+ (Toggle *)sharedInstance {
  static Toggle *toggle;
  if (!toggle) {
    toggle = [Toggle new];
  }
  return toggle;
}
- (BOOL)enableConfigureIPAddress {
  return NO;
}

@end
