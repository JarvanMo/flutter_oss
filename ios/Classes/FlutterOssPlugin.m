#import "FlutterOssPlugin.h"
#import <AliyunOSSiOS/OSSService.h>

@implementation FlutterOssPlugin
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
            methodChannelWithName:@"com.jarvanmo/flutter_oss"
                  binaryMessenger:[registrar messenger]];
    FlutterOssPlugin *instance = [[FlutterOssPlugin alloc] initWithRegistrar:registrar methodChannel:channel];
    [registrar addMethodCallDelegate:instance channel:channel];
}

NSObject <FlutterPluginRegistrar> *_OSSRegistrar;
FlutterMethodChannel *_OSSMethodChannel;
NSMutableDictionary *_authCredentialsProviderCache = [[NSMutableDictionary alloc] init];

- (instancetype)initWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar methodChannel:(FlutterMethodChannel *)flutterMethodChannel {
    self = [super init];
    _OSSRegistrar = registrar;
    _OSSMethodChannel = flutterMethodChannel;
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"FlutterOSS: uploadAsync" isEqualToString:call.method]) {
        [self uploadAsync:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}


- (void)uploadAsync:(FlutterMethodCall *)call result:(FlutterResult)result {
//    id<OSSCredentialProvider> credential = [[OSSAuthCredentialProvider alloc] initWithAuthServerUrl:@"应用服务器地址，例如http://abc.com:8080"];
    NSString *stsServer = call.arguments[@"stsServer"];
    id <OSSCredentialProvider> credential = _authCredentialsProviderCache[stsServer];
    if (!credential) {
        credential = [[OSSAuthCredentialProvider alloc] initWithAuthServerUrl:stsServer];
        _authCredentialsProviderCache[stsServer] = credential;
    }
    NSString *bucketName = call.arguments[@"bucketName"];
    NSString *endpoint = call.arguments[@"endpoint"];
    NSString *completerId = call.arguments[@"completerId"];
    NSString *filePath = call.arguments[@"filePath"];
    NSString *objectName = call.arguments[@"objectName"];

    OSSPutObjectRequest * put = [OSSPutObjectRequest new];
// 必填字段
    put.bucketName = bucketName;
    put.objectKey = objectName;
    put.uploadingFileURL = [NSURL fileURLWithPath:filePath];

    OSSClient *client = [[OSSClient alloc] initWithEndpoint:endpoint credentialProvider:credential];
    OSSTask * putTask = [client putObject:put];
    [putTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            NSDictionary *dictionary =@{
                    @"isSuccess":@YES,
                    @"completerId":completerId,
                    @"code":@0
            };
            [_OSSMethodChannel invokeMethod:@"FlutterOSS:uploadAsyncResult" arguments:dictionary];
        } else {
            NSDictionary *dictionary =@{
                    @"isSuccess":@YES,
                    @"completerId":completerId,
                    @"code":@-1,
                    @"message":task.error
            };
            [_OSSMethodChannel invokeMethod:@"FlutterOSS:uploadAsyncResult" arguments:dictionary];
        }
        return nil;
    }];

}


@end
