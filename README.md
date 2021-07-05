<div align="center">
<h1>Whiteboard</h1>
<p>This project is an open source version of White-SDK-IOS. In order to better display the source code structure, 'Whiteboard' divided the project into several 'subpods', which is more conducive to developers to view the source code level of the project. To do this, you need to modify the reference relationship.</p>
<p><a href="./README-zh.md">中文</a></p>
</div>

## TOC


- [The official documentation](#documentation)
- [Example](#Example)
  - [Debugging](#Debugging-specific-rooms)
- [The project structure](#The-project-structure)
- [Audio and video support](#Native-audio-and-video)
- [Dynamic PPT local resource pack](#Dynamic-PPT-local-resource-pack)
- [Part of the problem](#Part-of-the-problem)

## Documentation

[Official document](https://developer.netless.link) —— [iOS part](https://developer.netless.link/ios-zh/home)

## Reference

Podfile command

```
pod 'Whiteboard'
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


Running device: iOS 9 + (iOS 10 or above is recommended for a better experience)
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

## Part of the problem

1. The current SDK keyword is 'White', which is not strictly prefixed by three uppercase letters.
