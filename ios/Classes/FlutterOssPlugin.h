#import <Flutter/Flutter.h>
#import <AliyunOSSiOS/OSSService.h>
@interface FlutterOssPlugin : NSObject<FlutterPlugin>{}
@property (nonatomic, strong) OSSClient *ossClient;
@end
