<div align="center">
<h1>Whiteboard</h1>
<p>This project is an open source version of White-SDK-IOS. In order to better display the source code structure, 'Whiteboard' divided the project into several 'subpods', which is more conducive to developers to view the source code level of the project. To do this, you need to modify the reference relationship.</p>
<p><a href="./README-zh.md">中文</a></p>
</div>

[![bridge-check](https://github.com/netless-io/Whiteboard-iOS/actions/workflows/bridge.yml/badge.svg)](https://github.com/netless-io/Whiteboard-iOS/actions/workflows/bridge.yml) [![iOS13+Test](https://github.com/netless-io/Whiteboard-iOS/actions/workflows/test.yml/badge.svg)](https://github.com/netless-io/Whiteboard-iOS/actions/workflows/test.yml)

- [Documentation](#documentation)
- [Reference](#reference)
- [Example](#example)
  - [Debugging specific rooms](#debugging-specific-rooms)
  - [Unit testing](#unit-testing)
- [Device required](#device-required)
- [The project structure](#the-project-structure)
- [Native audio and video](#native-audio-and-video)
- [Dynamic PPT local resource pack](#dynamic-ppt-local-resource-pack)
- [FPA Network Acceleration (iOS 13 and above)](#fpa-network-acceleration-ios-13-and-above)
- [Custom App Plugin](#custom-app-plugin)
  - [Register the Custom App plugin](#register-the-custom-app-plugin)
  - [Adding custom App plugins to the whiteboard](#adding-custom-app-plugins-to-the-whiteboard)
- [Using YYKit](#using-yykit)
- [Part of the problem](#part-of-the-problem)

## Documentation

[Official document](https://developer.netless.link) —— [iOS part](https://developer.netless.link/ios-zh/home)

## Reference

- ### CocoaPods

```
pod 'Whiteboard'
```

- ### Swift Package Manager
```swift
 dependencies: [
    .package(url: "https://github.com/netless-io/Whiteboard-iOS.git", .upToNextMajor(from: "2.15.0"))
]
```

## Example

* Start Example

```shell
cd Example
pod install
```

Go to the Example folder and open the `Example.xcworkspace` project file.

>At the same time in `WhiteUtils.m`  fill in `WhiteSDKToken`, `WhiteAppIdentifier` according to the code comment


```Objective-C
/* FIXME: sdkToken
 Please register at https://console.netless.link and get the SDK token
This SDK token should not be stored on the client side, and all requests involving SDK tokens (all requests in the current class) should be placed on the server to avoid unnecessary risks caused by leaks.
 */
#define WhiteSDKToken <#@sdk Token#>
#define WhiteAppIdentifier <#@App identifier#>
```

### Debugging specific rooms

If you need to go to a specific room for debugging, go to the `Whiteboard-Prefix.pch` file, uncomment `WhiteRoomUUID` and `WhiteRoomToken` and fill in the specified contents.



```C

// If you add WhiteRoomUUID and WhiteRoomToken, then, you can define WhiteSDKToken as @""
//#define WhiteSDKToken <#@sdk Token#>
//#define WhiteAppIdentifier <#@App identifier#>

// If you need access to a specific room, uncomment the following two lines and fill in the corresponding UUID and RoomToken
//#define WhiteRoomUUID <#Room UUID#>
//#define WhiteRoomToken <#Room Token#>
```

At this point, if you add or replay a room, you will enter that room.


### Unit testing

Unit tests need to test some special behaviors, so the following operations are required for the corresponding room:


1. Inserted image interface (from the room that unit test started, image blocking is already enabled)
1. Sent specific custom events (defined in the unit test code)
1. Sent a lot of custom events



## Device required


Running device: iOS 10 + 
Development environment: Xcode 10+


## The project structure


SDK is composed of multiple `subpods`, and the dependency structure is shown in the following figure:

![Project dependency structure](./struct.jpeg)

> parameter configuration class: A class used to describe and store API parameters, return values, status, and other configuration items. Mainly used to interact with `webview`.

1. Object: The main function of Object is to handle the `JSON` conversion via `YYModel`. Contains the following parts:
    1. The `Object` base class, the base class of all the parameters used in the `SDK` configuration class.
    2. Some of the parameter configuration classes in `Room` and `Player` API.
2. Base: includes` SDK ` `Displayer` and some related classes, mainly as follows:
    1. `WhiteSDK` and its initialization parameter class.
    2. Generic callback `whiteCommonCallbacks` set by`WhiteSDK`
    3. Implementation of the same parent class `Displayer` as `Room` and `Player`.
    4. Some of the parameter configuration classes used by the `Displayer` API.
    5. `Displayer` is a class used to describe the current RoomState. It is the base class of `RoomState` and `PlayerState`.
3. Real-time Room
    1. `Room` class, and its related event callback class.
    2. `WhiteSDK+Room`, using the `SDK` API to create `Room`.
    3. Parameter configuration class unique to `Room`.
    4. Describe the class related to `Room`.
4. You can play back the contents of the room.
    1. `Player` class, and its related event callback class.
    2. `WhiteSDK+Player`, using the `SDK` API to create `Player`.
    3. The `Player` specific parameter configuration class.
    4. Describe the class related to the status of `Player`.
5. NativePlayer: Play audio and video on the `iOS` side, and synchronize with the whiteboard playing state
    1. `WhiteCombinePlayer` class, and some of its related classes.
6. Converter: Convert the request to the wrapper class.
* Charging for dynamic and static conversion is based on QPS (daily concurrency). The client cannot control the concurrency, so it is not recommended to use in production environment. Please refer to the documentation for details.



## Native audio and video


SDK now supports CombinePlayer to play audio and video in the Native end, and SDK will be responsible for synchronizing the state of audio and video with the whiteboard playback.

Specific code examples, see ` WhitePlayerViewController `
>m3u8 format of the audio and video, may need to be after a combinePlayerEndBuffering calls to ` seek `. (otherwise it may still start playing from the original position)

```Objective-C

#import <Whiteboard/Whiteboard.h>

@implementation WhitePlayerViewController
- (void)initPlayer
{

  // Create WhitePlayer logic

  // 1. Configure SDK initialization parameters, more parameters, see the WhitesdkConfiguration header file
  WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:[WhiteUtils appIdentifier]];
  // 2. Initialize the SDK
  self.sdk = [[WhiteSDK alloc] initWithWhiteBoardView:self.boardView config:config commonCallbackDelegate:self.commonDelegate];
  // 3. WhitePlayerConfig, Room UUID and RoomToken are required. For more parameters, see the WhitePlayerConfig.h header file
  WhitePlayerConfig *playerConfig = [[WhitePlayerConfig alloc] initWithRoom:self.roomUuid roomToken:self.roomToken];


  // This is an example of how to do this
  self.combinePlayer = [[WhiteCombinePlayer alloc] initWithMediaUrl:[NSURL URLWithString:@"https://netless-media.oss-cn-hangzhou.aliyuncs.com/c447a98ece45696f09c7fc88f649c082_3002a61acef14e4aa1b0154f734a991d.m3u8"]];

  // Display the AVPlayer screen
  [self.videoView setAVPlayer:self.combinePlayer.nativePlayer];

  // Configure the Delegate
  self.combinePlayer.delegate = self;

   
  [self.sdk createReplayerWithConfig:playerConfig callbacks:self.eventDelegate completionHandler:^(BOOL success, WhitePlayer * _Nonnull player, NSError * _Nonnull error) {
​    if (self.playBlock) {
​      self.playBlock(player, error);
​    } else if (error) {
​      NSLog(@"Failed to create playback room error:%@", [error localizedDescription]);
​    } else {
​      self.player = player;
​      [self.player addHighFrequencyEventListener:@"a" fireInterval:1000];

​      //Config WhitePlayer
​      self.combinePlayer.whitePlayer = player;
​      //WhitePlayer  need to manually seek to 0 to trigger the buffering behavior
​      [player seekToScheduleTime:0];
​    }
  }];
}

#pragma mark - WhitePlayerEventDelegate

- (void)phaseChanged:(WhitePlayerPhase)phase
{
  NSLog(@"player %s %ld", __FUNCTION__, (long)phase);
  // Attention! This must be done for the WhiteCombinePlayer to properly synchronize the state
  [self.combinePlayer updateWhitePlayerPhase:phase];
}

// Other callback methods...

#pragma mark - WhiteCombinePlayerDelegate

- (void)combinePlayerStartBuffering
{
  //Either end goes into the buffer
  NSLog(@"combinePlayerStartBuffering");
}

- (void)combinePlayerEndBuffering
{
  //Both ends end buffering
  NSLog(@"combinePlayerEndBuffering");
}

@end

```

## Dynamic PPT local resource pack


Principle: Download all the required dynamic-conversion-zip in advance, use the custom Scheme request supported by WKWebView iOS 11, intercept the WebView request, and return the local resources on the local side.

For specific implementation, please check the Git record:

1. Dependencies required：`add dependency to demo for ppt zip feature`
2. Code implementation：`implement local zip`

> Note that the current demo, realizes the interception, also need to `WhiteBaseViewController. M` , the `WhitePptParams` scheme parameter of the to `kPPTScheme`.

[dynamic-conversion-zip](https://developer.netless.link/server-zh/home/server-dynamic-conversion-zip)

## FPA Network Acceleration (iOS 13 and above)

1. Add `pod 'Whiteboard/fpa'` dependency in podfile
2. configure WhiteRoomConfig with `nativeWebSocket` as YES
3. If you want to listen to FPA connection status, you can call `[[FpaProxyService sharedFpaProxyService] setupDelegate:(id<FpaProxyServiceDelegate>)self];`

> Note that if you want to debug with iPhoneSimulator from M1 Device, please add the following statement to the Podfile.
```ruby
  post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
```

## Custom App Plugin

Custom App plugin can extend the whiteboard functionality, users write js code to implement their own whiteboard plugin.

[How to Develop Custom Whiteboard App](https://github.com/netless-io/window-manager/blob/master/docs/develop-app.md)

### Register the Custom App plugin

Native side needs to register the corresponding App to the SDK when using the custom App.

The registration method is `registerAppWithParams:` of `WhiteSDk`.

where `WhiteRegisterAppParams` has two ways to generate.
 1. copy the js code to the local project and inject the js string directly. Be careful with this method, you need to provide the variable name in js.
   
 ```Objective-C
@interface WhiteRegisterAppParams : WhiteObject
  
/** Create a custom app generated by js code
 @param javascriptString js code string
 @param kind plug-in type name, needs to be consistent across multiple ends
 @param appOptions additional parameters for plugin registration, fill in as needed
 @param variable The name of the app variable to be inserted in the above injected javascript
 */
+ (instancetype)paramsWithJavascriptString: (NSString *)javascriptString kind:(NSString *)kind appOptions:(NSDictionary *)appOptions variable:(NSString *)variable;
 ````
 2. Provide a download address for the js code, and let sdk do the downloading and injection. Be careful with this method, the App variable lookup will be determined by the kind parameter. Please keep the App variable name in js consistent with kind.
   ```Objective-C
@interface WhiteRegisterAppParams : WhiteObject
    
/** Create a custom app generated by remote js
 @param url js address
 @param kind The name of the plugin type, which needs to be consistent across multiple ends. (The whiteboard will use this name to find the app entry)
 @param appOptions Additional parameters for plugin registration, fill in as needed
 */
+ (instancetype)paramsWithUrl: (NSString *)url kind:(NSString *)kind appOptions:(NSDictionary *)appOptions;
   ```

### Adding custom App plugins to the whiteboard

The method to add a custom App is `addApp:comletionHandler:` of `WhiteRoom`

where `WhiteAppParam` is used to describe your custom app

Please call this method to complete the initialization of `WhiteAppParam`

```Objective-C
@interface WhiteAppParam : WhiteObject
 
/* Specific App, generally used to create custom App insertion parameters
 @param kind The kind used when registering the App
 @param options See [WhiteAppOptions](WhiteAppOptions) for details
 @param attrs Parameters to initialize the App, fill in as needed
 */
- (instancetype)initWithKind:(NSString *)kind options:(WhiteAppOptions *)options attrs:(NSDictionary *)attrs;
```

## Using YYKit

The default dependency of this SDK is YYModel, some users will have an error in the dependency if they use YYKit.

The solution is to modify the Podfile:

``` ruby
pod 'Whiteboard/Whiteboard-YYKit'
```

If you refer to fpa you can declare it like this:

``` ruby
pod 'Whiteboard/fpa-YYKit'
```

## Part of the problem

1. The current SDK keyword is 'White', which is not strictly prefixed by three uppercase letters.
