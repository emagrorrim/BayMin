//
//  Copyright © 2016 Christian Roman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HSVUtils : NSObject

float lowPassValue(size_t height, size_t width, uint8_t *buf, size_t bytesPerRow);

@end
