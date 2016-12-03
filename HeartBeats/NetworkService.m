//
//  Copyright © 2016 Christian Roman. All rights reserved.
//

#import "NetworkService.h"
#import <AFNetworking/AFNetworking.h>

@interface NetworkService()

@property (nonatomic, strong) AFHTTPSessionManager *manager;

@end

@implementation NetworkService

+ (NetworkService *)sharedService {
  static NetworkService *networkService;
  if (networkService != nil) {
    networkService = [NetworkService new];
  }
  return networkService;
}

- (void)configureHTTPSessionManagerWith:(NSURL *)url AndConfiguration:(NSURLSessionConfiguration * _Nullable)configuration  {
  _manager = [[AFHTTPSessionManager alloc] initWithBaseURL:url sessionConfiguration:configuration];
}

- (void)post:(NSString *)url parameters:(NSDictionary *)parameters success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
  [self.manager POST:url
          parameters:parameters
            progress:nil
             success:^(NSURLSessionDataTask *task, id responseObject) {
               if ([responseObject isKindOfClass:[NSDictionary class]]) {
                 success(responseObject);
               }
             }
             failure:^(NSURLSessionDataTask *task, NSError *error) {
               failure(error);
             }
   ];
}

- (AFHTTPSessionManager *)manager {
  if (!_manager) {
    _manager = [AFHTTPSessionManager new];
  }
  return _manager;
}

@end
