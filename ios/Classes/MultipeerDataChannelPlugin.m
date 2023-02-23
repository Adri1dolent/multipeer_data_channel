#import "MultipeerDataChannelPlugin.h"
#if __has_include(<multipeer_data_channel/multipeer_data_channel-Swift.h>)
#import <multipeer_data_channel/multipeer_data_channel-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "multipeer_data_channel-Swift.h"
#endif

@implementation MultipeerDataChannelPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMultipeerDataChannelPlugin registerWithRegistrar:registrar];
}
@end
