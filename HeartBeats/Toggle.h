//
//  Copyright © 2016 Christian Roman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Toggle : NSObject

+ (Toggle *)sharedInstance;
- (BOOL)enableConfigureIPAddress;

@end
