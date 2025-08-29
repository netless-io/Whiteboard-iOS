# iOS 多窗口使用文档

## 概述

White SDK iOS 支持多窗口功能，允许在同一房间中同时显示和管理多个应用程序窗口，如幻灯片、媒体播放器、文档查看器等。

## 基本配置

### 1. 启用多窗口功能

在初始化 WhiteSDKConfiguration 时，必须设置 `useMultiViews` 属性为 `YES` 来启用多窗口功能：

```objc
WhiteSDKConfiguration *configuration = [[WhiteSDKConfiguration alloc] initWithApp:appIdentifier];
configuration.useMultiViews = YES; // 启用多窗口功能
```

### 2. 创建 WhiteSdk 实例

```objc
self.whiteSdk = [[WhiteSdk alloc] initWithWhiteBoardView:self.whiteBoardView config:configuration];
```

### 3. 配置房间参数

```objc
WhiteRoomConfig *roomConfig = [[WhiteRoomConfig alloc] initWithUUID:uuid roomToken:token uid:userId];
roomConfig.windowParams = [self createWindowParams]; // 配置窗口参数
```

## 窗口管理

### 1. 创建窗口参数配置

```objc
- (WhiteWindowParams *)createWindowParams {
    WhiteWindowParams *windowParams = [[WhiteWindowParams alloc] init];
    windowParams.containerSizeRatio = @(9.0/16.0); // 设置窗口比例
    windowParams.chessboard = YES; // 显示棋盘背景
    windowParams.prefersColorScheme = WhitePrefersColorSchemeLight; // 设置主题
    return windowParams;
}
```

### 2. 添加幻灯片窗口

使用 `WhiteAppParam` 创建幻灯片应用：

```objc
// 使用任务ID和前缀URL创建幻灯片应用
NSString *prefixUrl = @"https://convertcdn.netless.link/dynamicConvert";
NSString *taskId = @"47f359400ab144498687xxxxxxxxxxxx";
WhiteAppParam *appParam = [WhiteAppParam createSlideApp:@"/dynamic" 
                                                 taskId:taskId 
                                                    url:prefixUrl 
                                                  title:@"Projector App"];
[self.room addApp:appParam completionHandler:^(NSString *appId) {
    if (appId) {
        NSLog(@"幻灯片应用添加成功，ID: %@", appId);
    }
}];
```

### 3. 添加媒体播放器窗口

```objc
// 创建媒体播放器应用
WhiteAppParam *appParam = [WhiteAppParam createMediaPlayerApp:@"https://example.com/video.mp4" 
                                                        title:@"player"];
[self.room addApp:appParam completionHandler:^(NSString *appId) {
    // 处理应用ID
}];
```

### 4. 添加静态文档窗口

```objc
// 创建静态文档查看器
WhiteAppParam *appParam = [WhiteAppParam createDocsViewerApp:@"/static" 
                                                      scenes:scenes 
                                                       title:@"static"];
[self.room addApp:appParam completionHandler:^(NSString *appId) {
    // 处理应用ID
}];
```

## 窗口操作

### 1. 关闭窗口

```objc
[self.room closeApp:appId completionHandler:^{
    NSLog(@"窗口关闭成功");
}];
```

### 2. 聚焦窗口

```objc
[self.room focusApp:appId];
```

### 3. 查询所有窗口

```objc
[self.room queryAllAppsWithCompletionHandler:^(NSDictionary<NSString *, WhiteAppSyncAttributes *> *apps, NSError *error) {
    if (!error) {
        NSLog(@"所有应用信息: %@", apps);
    }
}];
```

### 4. 查询单个窗口

```objc
[self.room queryApp:appId completionHandler:^(WhiteAppSyncAttributes *appParam, NSError *error) {
    if (!error) {
        NSLog(@"应用信息: %@", appParam);
    }
}];
```

## 完整示例

```objc
// 1. 配置SDK
WhiteSDKConfiguration *configuration = [[WhiteSDKConfiguration alloc] initWithApp:appIdentifier];
configuration.useMultiViews = YES; // 启用多窗口功能

// 2. 创建SDK实例
self.whiteSdk = [[WhiteSdk alloc] initWithWhiteBoardView:self.whiteBoardView config:configuration];

// 3. 配置房间参数
WhiteRoomConfig *roomConfig = [[WhiteRoomConfig alloc] initWithUUID:uuid roomToken:token uid:userId];

// 4. 设置窗口参数
WhiteWindowParams *windowParams = [[WhiteWindowParams alloc] init];
windowParams.containerSizeRatio = @(9.0/16.0);
windowParams.chessboard = YES;
windowParams.prefersColorScheme = WhitePrefersColorSchemeLight;
roomConfig.windowParams = windowParams;

// 5. 加入房间
[self.whiteSdk joinRoomWithConfig:roomConfig callbacks:self completionHandler:^(BOOL success, WhiteRoom *room, NSError *error) {
    if (success) {
        self.room = room;
        [self addSlide];
    }
}];

// 6. 添加应用窗口
- (void)addSlide {
    // 添加幻灯片应用
    NSString *prefixUrl = @"https://convertcdn.netless.link/dynamicConvert";
    NSString *taskId = @"47f359400ab1444986872db1723bb793";
    WhiteAppParam *appParam = [WhiteAppParam createSlideApp:@"/dynamic" 
                                                     taskId:taskId 
                                                        url:prefixUrl 
                                                      title:@"Projector App"];
    
    [self.room addApp:appParam completionHandler:^(NSString *appId) {
        if (appId) {
            NSLog(@"幻灯片应用添加成功，ID: %@", appId);
            self.slideAppId = appId;
        }
    }];
}
```

## 注意事项

1. **必须启用多窗口功能**：`configuration.useMultiViews = YES` 是使用多窗口功能的前提
2. **线程安全**：UI 操作必须在主线程执行