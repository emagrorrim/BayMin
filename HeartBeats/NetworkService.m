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
  if (networkService == nil) {
    networkService = [NetworkService new];
  }
  return networkService;
}

- (void)configureHTTPSessionManagerWith:(NSURL *)url {
  if (![url.absoluteString hasPrefix:@"http://"]) {
    url = [NSURL URLWithString:[@"http://" stringByAppendingString:url.absoluteString]];
  }
  _manager = [[AFHTTPSessionManager alloc] initWithBaseURL:url sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
  _manager.requestSerializer = [AFJSONRequestSerializer serializer];
  [_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
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
    NSString *plistPath = [[NSBundle mainBundle]pathForResource:@"Network" ofType:@"plist"];
    NSMutableDictionary *dataDic = [[NSMutableDictionary alloc]initWithContentsOfFile:plistPath];
    _manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:dataDic[@"root_url"]] sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  }
  return _manager;
}

@end
