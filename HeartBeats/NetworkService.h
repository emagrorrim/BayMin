//
//  Copyright © 2016 Christian Roman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkService : NSObject

+ (NetworkService *)sharedService;
- (void)post:(NSString *)url parameters:(NSDictionary *)parameters success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;
- (void)configureHTTPSessionManagerWith:(NSURL *)url AndConfiguration:(NSURLSessionConfiguration * _Nullable)configuration;

@end
