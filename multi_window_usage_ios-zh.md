# iOS 多窗口使用文档

## 简介

`Whiteboard-iOS` 在多窗口模式下内置了 `window-manager` 能力，Native 侧不需要直接挂载 Web 端的 `WindowManager.mount()`，而是通过 SDK 配置、房间参数和 `WhiteRoom` / `WhitePlayer` 暴露的接口来使用对应能力。

这份文档面向 iOS Native 接入方，重点说明：

- 如何启用多窗口能力
- 如何配置本地窗口参数
- 如何插入、关闭、聚焦和查询窗口
- 如何调整窗口显示样式
- 如何控制当前聚焦的文档窗口
- 如何处理 Slide 链接、音量和错误恢复

## 接入前提

使用多窗口能力前，需要同时满足下面两个条件：

1. 在 `WhiteSdkConfiguration` 中开启 `useMultiViews`
2. 在加入房间或创建回放时，根据需要设置 `windowParams`

如果没有开启 `useMultiViews`，下面文档中的窗口相关 API 都不会按多窗口语义工作。

## 初始化配置

### 实时房间

```objective-c
#import <Whiteboard/Whiteboard.h>

WhiteSdkConfiguration *sdkConfig = [[WhiteSdkConfiguration alloc] initWithApp:appIdentifier];
sdkConfig.useMultiViews = YES;

WhiteSDK *whiteSdk = [[WhiteSDK alloc] initWithWhiteBoardView:self.whiteBoardView
                                                       config:sdkConfig
                                       commonCallbackDelegate:self];

WhiteRoomConfig *roomConfig = [[WhiteRoomConfig alloc] initWithUUID:uuid
                                                          roomToken:roomToken
                                                                uid:userId];

WhiteWindowParams *windowParams = [[WhiteWindowParams alloc] init];
windowParams.containerSizeRatio = @(9.0 / 16.0);
windowParams.chessboard = YES;
windowParams.prefersColorScheme = WhitePrefersColorSchemeLight;

roomConfig.windowParams = windowParams;

[whiteSdk joinRoomWithConfig:roomConfig
                   callbacks:self
           completionHandler:^(BOOL success, WhiteRoom * _Nullable room, NSError * _Nullable error) {
    if (success) {
        self.room = room;
    }
}];
```

### 回放房间

如果你需要回放带窗口的房间，也要在 `WhitePlayerConfig` 中设置 `windowParams`，并且保证它与录制时的主要显示参数保持一致。

```objective-c
WhitePlayerConfig *playerConfig = [[WhitePlayerConfig alloc] initWithRoom:roomUuid
                                                                roomToken:roomToken];

WhiteWindowParams *windowParams = [[WhiteWindowParams alloc] init];
windowParams.containerSizeRatio = @(9.0 / 16.0);
windowParams.chessboard = YES;

playerConfig.windowParams = windowParams;

[whiteSdk createReplayerWithConfig:playerConfig
                         callbacks:self
                 completionHandler:^(BOOL success, WhitePlayer * _Nullable player, NSError * _Nullable error) {
    if (success) {
        self.player = player;
    }
}];
```

### `WhiteWindowParams` 常用字段

`WhiteWindowParams` 对应的是多窗口模式下的本地显示参数，只影响当前客户端，不会直接同步到远端。

- `containerSizeRatio`：多窗口区域的高宽比。建议多端保持一致，否则同一房间内可能出现布局不一致。
- `chessboard`：超出主窗口比例区域的部分是否显示棋盘背景。
- `prefersColorScheme`：窗口主题，支持 `Auto`、`Light`、`Dark`。
- `fullscreen`：是否默认以最大化窗口方式展示新窗口。
- `collectorStyles`：最小化窗口图标区域的样式配置。
- `overwriteStyles`：覆盖默认窗口样式。
- `debug`：是否输出多窗口相关调试日志。
- `polling`：是否定时更新本地视角。

## 核心窗口操作

### 插入窗口

`WhiteAppParam` 是 Native 侧对 `window-manager addApp` 的封装。常见内置窗口包括动态 PPT、静态文档和媒体播放器。

#### 插入动态 PPT

```objective-c
NSString *scenePath = @"/dynamic";
NSString *taskId = @"47f359400ab144498687xxxxxxxxxxxx";
NSString *prefixUrl = @"https://convertcdn.netless.link/dynamicConvert";

WhiteAppParam *appParam = [WhiteAppParam createSlideApp:scenePath
                                                 taskId:taskId
                                                    url:prefixUrl
                                                  title:@"Projector App"];

[self.room addApp:appParam completionHandler:^(NSString *appId) {
    NSLog(@"slide app id: %@", appId);
}];
```

#### 插入带自定义链接的动态 PPT

如果你的课件中需要把某些元素点击映射到自定义链接，可以使用 `WhiteSlideCustomLink`：

```objective-c
WhiteSlideCustomLink *link1 = [[WhiteSlideCustomLink alloc] initWithPageIndex:1
                                                                       shapeId:@"slide-9"
                                                                          link:@"https://www.example.com?t=1"];
WhiteSlideCustomLink *link2 = [[WhiteSlideCustomLink alloc] initWithPageIndex:1
                                                                       shapeId:@"slide-2"
                                                                          link:@"https://www.example.com?t=2"];

WhiteAppParam *appParam = [WhiteAppParam createSlideApp:@"/dynamic"
                                                 taskId:taskId
                                                    url:prefixUrl
                                                  title:@"Projector App"
                                            previewlist:@[]
                                           resourceList:@[]
                                            customLinks:@[link1, link2]];
```

#### 插入静态文档

```objective-c
WhiteAppParam *appParam = [WhiteAppParam createDocsViewerApp:@"/docs-viewer"
                                                      scenes:scenes
                                                       title:@"Static Docs"];
[self.room addApp:appParam completionHandler:^(NSString *appId) {
    NSLog(@"docs app id: %@", appId);
}];
```

#### 插入媒体播放器

```objective-c
WhiteAppParam *appParam = [WhiteAppParam createMediaPlayerApp:@"https://example.com/video.mp4"
                                                        title:@"Media Player"];
[self.room addApp:appParam completionHandler:^(NSString *appId) {
    NSLog(@"media app id: %@", appId);
}];
```

### 关闭窗口

```objective-c
[self.room closeApp:appId completionHandler:^{
    NSLog(@"close app finished");
}];
```

### 聚焦窗口

```objective-c
[self.room focusApp:appId];
```

### 查询所有窗口

```objective-c
[self.room queryAllAppsWithCompletionHandler:^(NSDictionary<NSString *, WhiteAppSyncAttributes *> *apps,
                                               NSError * _Nullable error) {
    if (!error) {
        NSLog(@"all apps: %@", apps);
    }
}];
```

### 查询单个窗口

```objective-c
[self.room queryApp:appId completionHandler:^(WhiteAppSyncAttributes * _Nullable app,
                                              NSError * _Nullable error) {
    if (!error) {
        NSLog(@"app info: %@", app);
    }
}];
```

## 窗口样式与状态

### 调整多窗口显示比例

`setContainerSizeRatio:` 会更新当前客户端的多窗口显示比例。

```objective-c
[self.room setContainerSizeRatio:@(3.0 / 4.0)];
```

### 切换窗口主题

```objective-c
[self.room setPrefersColorScheme:WhitePrefersColorSchemeDark];
```

### 读取当前 WindowManager attributes

如果你需要保存当前窗口布局、最大化状态或窗口集合信息，可以先读取当前 attributes。

```objective-c
[self.room getWindowManagerAttributesWithResult:^(NSDictionary *attributes) {
    NSLog(@"window manager attributes: %@", attributes);
}];
```

### 恢复或覆盖当前 WindowManager attributes

读取出的 attributes 可以在同一套多窗口参数前提下再写回，用于恢复布局状态。

```objective-c
[self.room setWindowManagerWithAttributes:attributes];
```

这里的 `attributes` 更适合做窗口状态恢复，不建议手写任意字段去“拼接”内部状态。更安全的做法是：

1. 从同一版本 SDK 中调用 `getWindowManagerAttributesWithResult:` 获取快照
2. 按原样存储
3. 在恢复场景中整体写回

## 文档窗口控制

`dispatchDocsEvent:options:completionHandler:` 用于操作当前聚焦的文档窗口。文档窗口加载完成前不要调用这个接口。

### 上一页 / 下一页

```objective-c
[self.room dispatchDocsEvent:WhiteWindowDocsEventPrevPage
                     options:nil
           completionHandler:^(bool success) {
    NSLog(@"prev page: %d", success);
}];

[self.room dispatchDocsEvent:WhiteWindowDocsEventNextPage
                     options:nil
           completionHandler:^(bool success) {
    NSLog(@"next page: %d", success);
}];
```

### 上一步 / 下一步

```objective-c
[self.room dispatchDocsEvent:WhiteWindowDocsEventPrevStep
                     options:nil
           completionHandler:^(bool success) {
    NSLog(@"prev step: %d", success);
}];

[self.room dispatchDocsEvent:WhiteWindowDocsEventNextStep
                     options:nil
           completionHandler:^(bool success) {
    NSLog(@"next step: %d", success);
}];
```

### 跳转到指定页

```objective-c
WhiteWindowDocsEventOptions *options = [[WhiteWindowDocsEventOptions alloc] init];
options.page = @(3);

[self.room dispatchDocsEvent:WhiteWindowDocsEventJumpToPage
                     options:options
           completionHandler:^(bool success) {
    NSLog(@"jump to page: %d", success);
}];
```

## Slide 相关接口

### 监听链接点击与错误

多窗口模式下，动态 PPT 的链接点击、资源拦截和错误恢复通常与 `WhiteSlideDelegate` 一起使用。

```objective-c
[whiteSdk setSlideDelegate:self];
```

```objective-c
#pragma mark - WhiteSlideDelegate

- (void)slideOpenUrl:(NSString *)url {
    NSLog(@"open url: %@", url);
}

- (void)onSlideError:(WhiteSlideErrorType)slideError
        errorMessage:(NSString *)errorMessage
             slideId:(NSString *)slideId
          slideIndex:(NSInteger)slideIndex {
    NSLog(@"slide error: %@, message: %@", slideError, errorMessage);
}
```

### Slide 资源拦截

如果你需要把 Slide 资源地址改写为自定义 CDN、本地缓存或签名地址，需要先开启：

```objective-c
sdkConfig.enableSlideInterrupterAPI = YES;
```

然后实现：

```objective-c
- (void)slideUrlInterrupter:(NSString * _Nullable)url
          completionHandler:(SlideUrlInterrupterCallback _Nullable)completionHandler {
    completionHandler(url);
}
```

### 设置和获取 Slide 音量

```objective-c
[whiteSdk updateSlideVolume:0.5];

[whiteSdk getSlideVolumeWithCompletionHandler:^(CGFloat volume, NSError *error) {
    if (!error) {
        NSLog(@"current volume: %f", volume);
    }
}];
```

### 恢复异常 Slide

当动态 PPT 资源错误、运行时错误或画布崩溃时，可以用 `recoverSlide` 尝试恢复：

```objective-c
[whiteSdk recoverSlide:slideId];
```

如果你希望恢复后直接跳到指定页：

```objective-c
[whiteSdk recoverSlide:slideId slideIndex:slideIndex + 1];
```

## 注意事项

1. `useMultiViews` 是所有窗口能力的前置条件，只设置 `windowParams` 不够。
2. `WhiteRoomConfig.windowParams` 和 `WhitePlayerConfig.windowParams` 只影响本地显示，不会自动同步到其他端。
3. `containerSizeRatio` 建议各端保持一致，否则同房间展示区域可能错位。
4. 重复插入同一个 PPT 时，`addApp` 可能失败，返回的 `appId` 为 `nil`。
5. `dispatchDocsEvent` 只适用于当前聚焦的文档窗口，并且不适合在转场动画未结束时连续调用。
6. `getWindowManagerAttributesWithResult:` / `setWindowManagerWithAttributes:` 更适合做状态快照恢复，不建议把它当作公开、稳定的手写配置协议来维护。
7. `slideUrlInterrupter` 只有在 `enableSlideInterrupterAPI = YES` 时才会触发。
8. `recoverSlide` 更适合用于异常恢复，不建议把它当作日常翻页接口使用。
