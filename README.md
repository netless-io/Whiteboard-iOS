# Whiteboard

本项目为 White-SDK-iOS 的开源版本，源码结构层次有改动，实现基本一致。

## 迁移

为了更好的显示源码结构，Whiteboard将项目分为了多个`subpod`，更有利于开发者查看项目源码层级。为此需要修改引用关系。

旧项目迁移，只需要将

```Objective-C
#import <White-SDK-iOS/WhiteSDK.h>
```

更换为

```Objective-C
import <Whiteboard/Whiteboard.h>
```

即可。


## Example

* 启动Example

```shell
cd Example
pod install
```

进入Example文件夹，打开 `Example.xcworkspace` 项目文件。

>同时在 `WhiteUtils.m` 根据提示修改当前部分内容。

```Objective-C
+ (NSString *)sdkToken
{
    /* FIXME: 此处 tonken 只做 demo 试用。
     token 请从 https://console.herewhite.com 注册获取。
     该 sdk token 不应该保存在客户端中，所有涉及 sdk token 的请求（当前类中所有请求），都应该放在服务器中。此处只做演示使用。
     */
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"white-sdk-token"];
}
```

## Requirements

iOS 9 +(推荐iOS 10以上使用，以获得更佳体验)
Xcode 10+

## Installation

在项目的`Podfile`文件中，添加以下内容：

```shell
pod 'Whiteboard'
```

在实际项目中，使用：

```Objective-C
#import <Whiteboard/Whiteboard.h>
# 使用白板sdk中任意类
```

## 项目结构

SDK由多个`subpod`组成，依赖结构如下图所示：

![项目依赖结构](./struct.jpeg)

>参数配置类：用于描述和存储API参数，返回值，状态等配置项的类。主要用于与`webview`进行交互。

1. Object：主要作用是通过`YYModel`处理`JSON`转换。包含以下部分：
    1. `Object`基类，所有`sdk`中使用的参数配置类的基类。
    2. `Room`，`Player`中API所涉及到的一些参数配置类。
2. Base：包含`SDK``Displayer`以及部分相关类，主要为以下部分：
    1. `WhiteSDK`以及其初始化参数类。
    2. `WhiteSDK`设置的通用回调`WhiteCommonCallbacks`
    3. `Room`与`Player`共同的父类`Displayer`类的实现。
    4. `Displayer`中API所使用的一些参数配置类。
    5. `Displayer`用来描述当前房间状态的类，为`RoomState`,`PlayerState`的基类。
3. Room：实时房间相关内容：
    1. `Room`类，及其相关事件回调类。
    1. `WhiteSDK+Room`，使用`SDK`创建`Room`的API。
    1. `Room`特有的参数配置类。
    1. 描述`Room`状态相关的类。
4. Player：回放房间相关内容：
    1. `Player`类，及其相关事件回调类。
    1. `WhiteSDK+Player`，使用`SDK`创建`Player`的API。
    1. `Player`特有的参数配置类。
    1. 描述`Player`状态相关的类。
5. NativePlayer：在`iOS`端播放音视频，并与白板播放状态做同步
    1. `WhiteCombinePlayer`类，及其相关部分类。
6. Converter：动静态转换请求封装类。
    * 动静态转换计费以QPS（日并发）计算，客户端无法控制并发，不推荐在生产环境下使用。详情请参考文档。

## 文档

[文档](https://developer.netless.link)

### native 端播放音视频

```Objective-C
#import <Whiteboard/Whiteboard.h>

@implementation WhitePlayerViewController

- (void)initPlayer
{

    // 创建 WhitePlayer逻辑
    // 1. 配置 SDK 初始化参数，更多参数，可见 WhiteSdkConfiguration 头文件
    WhiteSdkConfiguration *config = [WhiteSdkConfiguration defaultConfig];
    // 2. 初始化 SDK
    self.sdk = [[WhiteSDK alloc] initWithWhiteBoardView:self.boardView config:config commonCallbackDelegate:self.commonDelegate];

    // 3. 配置 WhitePlayerConfig，room uuid 与 roomToken 为必须。其他更多参数，见 WhitePlayerConfig.h 头文件
    WhitePlayerConfig *playerConfig = [[WhitePlayerConfig alloc] initWithRoom:self.roomUuid roomToken:self.roomToken];
    
    // 4. 创建 WhitePlayer ，并设置 Player的 callbacks
    [self.sdk createReplayerWithConfig:playerConfig callbacks:self.eventDelegate completionHandler:^(BOOL success, WhitePlayer * _Nonnull player, NSError * _Nonnull error) {
        if (error) {
            # 错误处理
        } else {
            
            // CombinePlayer 处理逻辑
            // 1. 传入系统AVPlayer支持的播放文件格式，并将初始化成功的 WhitePlayer 一起传入
            self.combinePlayer = [[WhiteCombinePlayer alloc] initWithMediaUrl:[NSURL URLWithString:@"请确认该地址正确有效可访问，否则后续会回调 - (void)combineVideoPlayerError:(NSError *)error 方法，无法正常播放"] whitePlayer:player];
            // 2. 设置 CombinePlayer 代理，以接受回调
            self.combinePlayer.delegate = self;
            // 3. 设置用来显示视频的 View
            // 在 - (void)phaseChanged:(WhitePlayerPhase)phase 回调中，主动更新 WhiteCombinePlayer 的whitePlayer状态
            [self.videoView setAVPlayer:self.combinePlayer.nativePlayer];
            // 5. 播放，等待 CombinePlayer
            [self.combinePlayer play];
        }
    }];
}

#pragma mark - WhitePlayerEventDelegate

- (void)phaseChanged:(WhitePlayerPhase)phase
{
    NSLog(@"player %s %ld", __FUNCTION__, (long)phase);
    // 注意！必须完成该操作，WhiteCombinePlayer 才能正确同步状态
    [self.combinePlayer updateWhitePlayerPhase:phase];
}

// 其他回调方法...

#pragma mark - WhiteCombinePlayerDelegate
- (void)combinePlayerStartBuffering
{
    //任意一端进入缓冲
    NSLog(@"combinePlayerStartBuffering");
}

- (void)combinePlayerEndBuffering
{
    //两端都结束缓冲
    NSLog(@"combinePlayerEndBuffering");
}


@end

```
