//
//  Copyright © 2016 Christian Roman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkService : NSObject

+ (NetworkService  * _Nonnull)sharedService;
- (void)post:(NSString * _Nonnull)url parameters:(NSDictionary * _Nonnull)parameters success:(void (^ _Nullable)(NSDictionary * _Nonnull))success failure:(void (^ _Nullable)(NSError * _Nullable))failure;
- (void)configureHTTPSessionManagerWith:(NSURL * _Nonnull)url;

@end
