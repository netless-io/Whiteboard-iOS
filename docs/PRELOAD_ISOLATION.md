# 显式预加载与普通入房（2.16.149）

与 Android 2.16.136 对齐，内嵌正式 Bridge 0a3fd1f：White Web SDK 2.16.63、Appliance Plugin 1.1.49、WindowManager 1.0.29、Slide 0.2.109。

## 参数与默认值

| iOS 参数 | Android 对应参数 | 默认行为 |
| --- | --- | --- |
| `enableModelPreload` | 同名 | `NO`，不开启模型 JS 预加载 |
| `dynamicConfig` | 同名 | `nil`，不预取动态配置；配置 Region → iOS JSON URL 后自动预取 |
| `preloadBuiltinApps` | 同名 | `nil` 或 `@[]` 均关闭；显式非空列表才准备 App 类 |
| `enableAppliancePlugin` | 同名 | `NO`；`YES` 启用教具功能，默认仍后置初始化 |
| `enablePreLoadAppliancePlugin` | 同名，大小写固定 | `NO`；和上一项同时为 `YES` 才提前准备教具探针/Worker |
| `appliancePluginOptions` | 同名 | 未配置时按插件默认值；`extras` 可设置 `useWorker`、`useSimple` 等 |

支持的 App 类为 `Slide`、`Presentation`、`MediaPlayer`、`DocsViewer`。准备类不等于创建 App 实例或加载具体课件。模型预加载需要后端支持：当前后台在 dev 环境，生产环境灰度完成后才可开启。

## 普通入房

```objc
WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:appIdentifier];
config.region = WhiteRegionCN;
config.useMultiViews = YES;
config.enableAppliancePlugin = YES; // 仅启用教具，保持入房后初始化。
WhiteSDK *sdk = [[WhiteSDK alloc] initWithWhiteBoardView:board config:config commonCallbackDelegate:nil];
[sdk joinRoomWithConfig:roomConfig callbacks:roomCallbacks completionHandler:completion];
```

不配置四类可选预加载时，不启动其准备任务，也不发出 `sdk.observePreload`。流程为基础 JS SDK → 原 SDK 入房 → Room → WindowManager → 按实际参数取得 Worker 资源 → 教具初始化。SDK 构造原有 regions 请求保留。

## 候课页与入房页复用

```objc
// 候课页：保留同一个 WhiteBoardView 和 WhiteSDK，并使 View 保持附着。
WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:appIdentifier];
config.region = WhiteRegionCN;
config.useMultiViews = YES;
config.enableAppliancePlugin = YES;
config.enablePreLoadAppliancePlugin = YES; // 显式前置教具探针及必要 Worker。
config.preloadBuiltinApps = @[@"Slide", @"Presentation"]; // 显式准备 App 类。
WhiteSDK *sdk = [[WhiteSDK alloc] initWithWhiteBoardView:board
                                               config:config
                               commonCallbackDelegate:self];
[sdk prepareWithCompletionHandler:^(NSError *error) {
    // 可选的基础准备通知：JS SDK 已创建；不代表所有预加载或课件 ready。
    if (error) { /* 处理本次显式等待失败 */ }
}];
// 入房页：展示/移动上面的原 View，直接使用同一个 sdk 调用 joinRoom。
[sdk joinRoomWithConfig:roomConfig callbacks:roomCallbacks completionHandler:completion];
```

在 `WhiteCommonCallbackDelegate` 实现中接收可选准备结果：

```objc
- (void)onPreloadStateChange:(WhitePreloadResult *)result {
    // 已开启的可选任务完成后仅通知一次 success / warn。
    // warn 时正常入房仍可继续；业务无需以此回调作为 joinRoom 的前置条件。
}
```

`prepareWithCompletionHandler:` 与 `onPreloadStateChange:` 对齐 Android 的 `prepareCompletion` 与同名回调；前者是基础准备，后者是可选预加载结果，两者都不表示可绘制或课件像素首帧。构造后立即 `joinRoom` 同样支持。

构造阶段不新增 15 秒截止时间。默认 15 秒只作用于显式 `prepareWithCompletionHandler:` 等待；Native 总入房超时沿用 45 秒。模型/动态配置仅在实际入房时按 SDK 既有 120 秒/5 秒等待预加载，失败或超时回退原加载。

教具参数按 JS 文档首份配置生效：前置时在 SDK 级设置；后置时首次实际初始化按 Room 显式参数 > SDK 显式参数 > 远端配置 > 默认值。动态配置失败或取消时，教具首次参数由实际 Room 正常路径决定。

## 资源生命周期与 Demo

- `mainThread` 不创建内置 Worker Blob；`auto` 且 `useSimple` 省略/`YES` 仅 Full；`useSimple=NO` 为 Full+Sub。
- Worker 源码和 Blob URL 在同一 JS 文档内复用，离房不撤销；销毁原 View/文档时释放。探针临时 Worker 完成后终止；绘制 Worker 随实际离房销毁。
- `releaseRoom` 只释放 Native 引用，不能替代 `leaveRoomWithCompletionHandler:`。
- Example 的“普通入房”入口在点击后创建 View/SDK 并立即入房；“预加载入房”入口保留已准备的原 View/SDK，待点击后复用。`WhiteLaunchPreloadViewController` 提供两种入口及上述回调注释。
- `WhiteReleaseE2EController`、KIF 物理触摸和可控异常均为 Debug Example 测试夹具，不包含在 SDK Pod/SPM 中。
