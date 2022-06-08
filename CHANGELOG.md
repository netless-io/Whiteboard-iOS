# ChangeLog
本项目的所有值得注意的更改都将记录在此文件中。

---


# Whiteboard 版本记录
- 基于 White-SDK-iOS 基础上，整理结构，进行开源。
开源版本，版本延续旧版本数字，在此数字基础上，进行版本更新。
## [2.16.24] - 2022-06-09
- 更新`@netless/window-manager`至 0.4.30
- `WhiteRoom`新增`removePage`方法，用于删除主白板画布
- 修复重连之后， app 创建失败的错误
- 增加`WhiteReplayer`的 seeking 回调
## [2.16.23] - 2022-06-02
- 更新`@netless/window-manager`至 0.4.26
- 更新`iframe-bridge`至 2.1.9
- 修复多窗口模式下主白板`sceneState`发生变化时没有触发`WhiteRoomCallbackDelegate`的`fireRoomStateChanged`的错误
## [2.16.22] - 2022-05-30
- 更新 `white-web-sdk` 至 2.16.24
- 更新 `@netless/app-slide` 至 0.2.1
- 修复 单窗口模式下 `Room.sceneState` 不回调问题
- 修复 PPT 文字排版显示问题
## [2.16.21] - 2022-05-16
- 更新`@netless/window-manager`至 0.4.25
- 新增仅 ApplePencil 涂鸦选项，详见 `WhiteRoomConfig.drawOnlyApplePencil`和`WhiteRoom.setDrawOnlyApplePencil`
- `WhiteRoom`新增`setPrefersColorScheme`方法，用于更改多窗口暗色模式。
- `WhiteRoom`新增`setContainerSizeRatio`方法，用于更新多窗口显示比例。
- `WhiteCombinePlayer`支持单白板或者单Native播放。
## [2.16.20] - 2022-05-06
- 更新`white-web-sdk`至 2.16.20
## [2.16.19] - 2022-04-24
- 更新`white-web-sdk`至 2.16.19
- 兼容YYKit, 详见README
## [2.16.18] - 2022-04-20
- 更新`@netless/window-manager`至 0.4.23
- 修复可写进入立即切换成只读造成初始化 camera 失败的问题
- 修复只读端先加入时视角跟随失败的问题
## [2.16.17] - 2022-04-14
- 更新`@netless/app-slide`至 0.1.3
## [2.16.16] - 2022-04-12
- 更新`@netless/window-manager`至 0.4.21
## [2.16.15] - 2022-04-08
- 更新`white-web-sdk`至2.16.15
- `WhiteDisplayer`中新增`getSceneFromScenePath:`方法
- `WhiteSdkConfiguration`中新增`disableNewPencilStroke`参数，默认为NO，设置为YES后可以禁止新铅笔工具展示笔锋
- 修改依赖`dsbridge`为`NTLbridge`。2.16.14及以下版本的用户升级到2.16.15以上时，如果遇到关于dsbridge的报错，请先尝试重新运行一遍`pod install`，删除所有缓存之后再重新编译。
## [2.16.14] - 2022-04-01
- 更新`@netless/window-manager`至 0.4.20
- 更新`@netless/app-slide`至 0.1.1
- 更新`iframe-bridge`至 2.1.8
- 加了锁定ppt 的功能，小窗口 ppt 里面的白板，禁止拖动。
## [2.16.13] - 2022-03-28
- 更新`@netless/window-manager`至 0.4.18
- 修复单窗口模式下，iframe 不显示的问题
## [2.16.12] - 2022-03-28
- 更新`@netless/window-manager`至 0.4.17
- 修复 safari 浏览器下 removeScenes 为 "/" 没有清理完成完成时可以 addApp
- 升级`@netless/app-slide`至0.1.0
## [2.16.11] - 2022-03-25
- 修复多窗口下，快速修改 RoomState 内容，会丢失部分状态变化的问题
## [2.16.10] - 2022-03-25
- 更新`@netless/window-manager`至 0.4.15
- 修复 remove 根 scenes 时,  切换主白板和 app focus 失效的问题
- `WhiteRoom`新增`closeApp`方法
## [2.16.9] - 2022-03-24
- `WhiteSDK`新增`registerAppWithParams`方法，可以通过该方法注册自定义App。详见README
## [2.16.8] - 2022-03-22
- 更新`@netless/window-manager`至 0.4.14
- 修复 removeScenes 为 "/" 时， 同步端笔迹依旧存在的问题
## [2.16.7] - 2022-03-16
- 更新`@netless/window-manager`至 0.4.13
- 修复 多窗口模式下，只读状态时 `viewMode` 无法从 `freedom` 切换回 `broadcaster` 问题
## [2.16.6] - 2022-03-10
- 更新`window-manager`至0.4.11
- `WhiteRoom`新增`WhitePageState`属性，开启多窗口之后，主白板的页面数状态需要在该属性中读取。
## [2.16.5] - 2022-03-01
- 更新`window-manager`至0.4.9
## [2.16.4] - 2022-02-24
- 新增`Whiteboard/fpa`subspec。在 podfile 添加 `pod 'Whiteboard/fpa'` 依赖，并且配置 WhiteRoomConfig 的 `nativeWebSocket` 为 YES 即可进行加速。
## [2.16.3] - 2022-02-24
- 更新`window-manager`至0.4.7
- 新增`WhiteConverterV5`, 用于查询文件转码进度
- `WhiteRoom`新增`addPage`, `prevPage` 和 `nextPage`方法
## [2.16.2] - 2022-02-22
- 更新`white-web-sdk`至2.16.10
- 修复WhiteRoom的`undoSteps`和`redoSteps`的回调错误
## [2.16.1] - 2022-02-16
- 更新`white-web-sdk`至2.16.9
- 更新`window-manager`至0.4.5
## [2.16.0] - 2022-02-11
- 更新`@netless/window-manager`至 0.4.1
- 更新`white-web-sdk`至2.16.7
- 增加`WhiteRoom`调用日志逻辑。开关跟随`WhiteSdkConfiguration`中的 log 参数（默认关闭），上报等级为 info，上报配置跟随`loggerOptions`配置项。
- 回放支持多窗口模式，需要在初始化 SDK 时，配置`WhiteSdkConfiguration`开启 useMultiViews 参数。
- `WhiteRoom`新增`insertText`方法，可以通过该方法在指定位置插入文字。
- 修复多窗口模式下，`Redo`和`Undo`不生效的问题。
## [2.15.28] - 2022-06-01
- 更新`@netless/iframe-bridge`至 2.1.9
## [2.15.27] - 2022-03-09
- 更新`@netless/window-manager`至 0.3.27
## [2.15.26] - 2022-03-02
- 更新`@netless/window-manager`至 0.3.26
## [2.15.25] - 2022-01-20
- 更新`@netless/window-manager`至 0.3.25
- 更新`@netless/app-slide`至 0.0.56
- 更新`white-web-sdk`至2.15.17
## [2.15.23] - 2022-01-18
- 更新`@netless/window-manager`至 0.3.23
- 更新`white-web-sdk`至2.15.16
- 更新`@netless/video-js-plugin` 至 0.3.8
## [2.15.22] - 2022-01-13
- 更新`@netless/window-manager`至 0.3.19
## [2.15.21] - 2022-01-12
- 更新`white-web-sdk`至 2.15.15
## [2.15.20] - 2022-01-04
- 多窗口模式，增加最大化，最小化，普通模式回调，具体见`WhiteRoomState`类`windowBoxState`属性。
- 多窗口窗体初始化时，支持配置夜间模式主题，具体见`WhiteRoomConfig`配置类中`WhiteWindowParams`的`prefersColorScheme`属性。
## [2.15.19] - 2021-12-29
- 更新`@netless/app-slide`至 0.0.53
## [2.15.18] - 2021-12-28
- 更新`@netless/window-manager`至 0.3.17
## [2.15.17] - 2021-12-23
- 更新`@netless/window-manager`至 0.3.16
## [2.15.16] - 2021-12-22
- 更新`@netless/app-slide`至 0.0.52
## [2.15.15] - 2021-12-20
- 更新`@netless/window-manager`至 0.3.14
- 更新`@netless/app-slide`至 0.0.51
## [2.15.14] - 2021-12-17
- 降级`@netless/window-manager`至 0.3.11
- 更新`@netless/app-slide`至 0.0.50
## [2.15.13] - 2021-12-16
- 更新`white-web-sdk`至 2.15.13
- 更新`@netless/app-slide`至 0.0.46
## [2.15.12] - 2021-12-14
- 更新`@netless/window-manager`至 0.3.12
- 更新`@netless/app-slide`至 0.0.44
## [2.15.11] - 2021-12-14
- 更新`@netless/app-slide`至 0.0.43，优化动态 PPT 显示效果
## [2.15.10] - 2021-12-14
- 优化 native 端截图 API，恢复图片支持，同时支持多窗口模式
- 更新`@netless/window-manager`至 0.3.11
- 更新`@netless/app-slide`至 0.0.42
## [2.15.8] - 2021-12-13
- 修复多窗口模式下，重连失败，且没有回调的问题
- 更新`@netless/app-slide`至 0.0.39
## [2.15.7] - 2021-12-09
- 更新`@netless/window-manager`至 0.3.9
- 更新`@netless/app-slide`至 0.0.36
## [2.15.6] - 2021-12-07
- 更新`white-web-sdk`至 2.15.11
- 更新`@netless/window-manager`至 0.3.8
- 更新`@netless/app-slide`至 0.0.35
- 修复多窗口视频插件，插入视频地址无效的问题
## [2.15.5] - 2021-11-24
- 更新`white-web-sdk`至 2.15.7
- 更新`@netless/window-manager`至 0.3.7
## [2.15.4] - 2021-11-23
- 更新`white-web-sdk`至 2.15.6
- 更新`@netless/window-manager`至 0.3.5
- 更新`@netless/app-slide`至 0.0.27
## [2.15.3] - 2021-11-22
- 更新`white-web-sdk`至 2.15.6
- 更新`@netless/window-manager`至 0.3.2
- 更新`@netless/app-slide`至 0.0.25
## [2.15.2] - 2021-11-17
- 更新`white-web-sdk`至 2.15.4
- 更新`@netless/window-manager`至 0.2.19
- 更新`@netless/app-slide`至 0.0.22
- 优化 `useMultiViews` 为 true 时，cameraState 状态回调
## [2.15.1] - 2021-11-09
- 更新`white-web-sdk`至 2.15.3
- 更新`@netless/window-manager`至 0.2.17
## [2.15.0] - 2021-11-01
- 更新`white-web-sdk`至 2.15.1
- <span style="color: red">WhiteRoomConfig 现在需要强制配置 UID</span>，其初始化方法，更改为`- (instancetype)initWithUUID:(NSString *)uuid roomToken:(NSString *)roomToken uid:(NSString *)uid userPayload:(id _Nullable)userPayload`和`- (instancetype)initWithUUID:(NSString *)uuid roomToken:(NSString *)roomToken uid:(NSString *)uid`，移除旧的初始化 API。
- <span style="color: red">移除 WhiteSDK 部分 API，强制使用 WhiteRoomConfig 调用加入房间接口。</span>`
    * `- (void)joinRoomWithUuid:(NSString *)uuid roomToken:(NSString *)roomToken completionHandler:(void (^)(BOOL success, WhiteRoom * _Nullable room, NSError * _Nullable error))completionHandler;`
  * `- (void)joinRoomWithRoomUuid:(NSString *)roomUuid roomToken:(NSString *)roomToken callbacks:(nullable id<WhiteRoomCallbackDelegate>)callbacks completionHandler:(void (^) (BOOL success, WhiteRoom * _Nullable room, NSError * _Nullable error))completionHandler;`
## [2.14.6] - 2021-10-28
- 更新`white-web-sdk`至 2.14.7
- 多窗口支持显示单页模式 ppt
## [2.14.5] - 2021-10-22
- 更新`@netless/window-manager`至 0.2.9,修复`WhiteSdkConfiguration`中`useMultiViews`为 true，writable 为 false，userCursor 为 true 进入一个没有多窗口内容的房间后，再切换回 writable 为 true 时，无法绘制的问题。
## [2.14.4] - 2021-10-22
- 更新`@netless/window-manager`至 0.2.8,修复`WhiteSdkConfiguration`中`useMultiViews`为 true 时，以 writable 为 false 进入一个没有多窗口内容的房间时，出现报错，或者无回调的问题。
## [2.14.3] - 2021-10-21
- 更新`white-web-sdk`至 2.14.5
## [2.14.2] - 2021-10-15
- 更新`white-web-sdk`至 2.14.4
- 更新`@netless/window-manager`至 0.2.5，修复`WhiteSdkConfiguration`中`useMultiViews`为 true 时，`WhiteRoomConfig`的 `disableCameraTransform` true 无法生效的问题。
## [2.14.1] - 2021-10-11
- 更新`white-web-sdk`至 2.14.4
## [2.14.0] - 2021-10-09
- 更新`white-web-sdk`至 2.14.3，支持多窗口模式。具体见 `WhiteSdkConfiguration` 类中的`useMultiViews` 以及`WhiteRoomConfig`的`windowParams` 属性注释，多窗口暂时不支持回放。 
- <span style="color: red">不再兼容 iOS 9</span> 
## [2.13.21] - 2021-09-09
- 更新`white-web-sdk`至 2.13.20
## [2.13.20] - 2021-08-20
- 更新`white-web-sdk`至 2.13.18
## [2.13.19] - 2021-08-13
- 更新`white-web-sdk`至 2.13.17
- 关闭`allowUniversalAccessFromFileURLs`功能，该功能关闭后，会影响本地截图功能，无法渲染不带跨域头的图片。
## [2.13.18] - 2021-08-11
- 更新`white-web-sdk`至 2.13.16
## [2.13.17] - 2021-08-05
- 更新`white-web-sdk`至 2.13.14
- `WhiteCommonCallbackDelegate`新增日志输出接口`- (void)logger:(NSDictionary *)dict`。具体见 API 注释
## [2.13.16] - 2021-07-26
- 更新`white-web-sdk`至 2.13.12
## [2.13.15] - 2021-07-17
- 更新`white-web-sdk`至 2.13.11
## [2.13.14] - 2021-07-15
- 更新`@netless/video-js-plugin`至 0.3.3
- 修复`WhiteboardView`的`backgroundColor`属性，修复设置颜色后，加入房间颜色重置，修复颜色闪烁问题。
## [2.13.13] - 2021-07-14
- 更新`@netless/video-js-plugin`至 0.3.2
## [2.13.12] - 2021-07-13
- 更新`@netless/video-js-plugin`至 0.3.0
## [2.13.11] - 2021-07-12
- 更新`@netless/video-js-plugin`至 0.3.0.beta.10
## [2.13.10] - 2021-07-12
- 修复 2.13.6 出现的 refreshViewSize 调用无效的问题
## [2.13.9] - 2021-07-09
- 更新`@netless/video-js-plugin`至 0.2.1
## [2.13.8] - 2021-07-08
- 更新`white-web-sdk`至 2.13.10。修复 2.13.x 版本中，第一笔无法正常绘制的问题
## [2.13.7] - 2021-07-07
- 更新`@netless/video-js-plugin`至 0.2.0
## [2.13.6] - 2021-07-06
- 更新`white-web-sdk`至 2.13.9。主要优化 ppt 前端展示逻辑，优化书写性能，以及时间戳同步功能。
- 优化`WhiteboardView`的`backgroundColor`属性，现在修改 WhiteboardView 颜色，可以直接使用修改`backgroundColor`，弃用`WhiteDisplayer`中`backgroundColor`方法。
## [2.13.5] - 2021-06-21
- 更新`white-web-sdk`至 2.13.6
## [2.13.4] - 2021-06-15
- 更新`white-web-sdk`至 2.13.4
## [2.13.2] - 2021-06-11
- 更新`white-web-sdk`至 2.13.3
## [2.13.1] - 2021-06-11
- 更新`white-web-sdk`至 2.13.2
- 修复设置为 disableDeviceInputs 后 iframe 插件，有一定情况仍然能够接受交互的情况
## [2.12.34] - 2021-07-06
- 更新`white-web-sdk`至 2.12.23
## [2.12.33] - 2021-06-08
- 修复处于 clicker 教具，进行缩放后，出现的视野异常问题
## [2.12.32] - 2021-06-07
- 更新`@netless/cursor-tool`至 0.1.0
- 更新`@netless/iframe-bridge`至 2.1.2
## [2.12.31] - 2021-06-04
- 更新`white-web-sdk`至 2.12.21
- 更新`@netless/video-js-plugin`至 0.1.5
## [2.12.30] - 2021-06-02
- 修复`@netless/video-js-plugin`不显示问题
## [2.12.29] - 2021-06-01
- 更新`@netless/video-js-plugin`至 0.1.3, 修复低版本WebView兼容问题
## [2.12.28] - 2021-05-25
- 更新`@netless/cursor-tool`至 0.0.9
## [2.12.27] - 2021-05-24
- 更新`white-web-sdk`至 2.12.20
- 添加`@netless/video-js-plugin`插件支持
## [2.12.26] - 2021-05-20
- 更新`white-web-sdk`至 2.12.18
- 添加`clicker`教具，用以提供给 h5 课件操作交互
## [2.12.25] - 2021-05-17
- 更新`white-web-sdk`至 2.12.18
- 修复部分常量命名
- 默认开启服务器端排版本，同时加载服务器端裁剪字体。具体参考`WhitePptParams`的`useServerWrap`属性注释。
## [2.12.24] - 2021-05-13
- 新增`syncBlockTimestamp`API，详情见`room.syncBlockTimestamp`方法
- 新增`ApplianceShape`教具，详情见`WhiteApplianceShapeTypeKey`,`WhiteMemberState`的`shapeType`属性
- 更新`white-web-sdk`至 2.12.17
## [2.12.23] - 2021-05-11
- 增加新的 `RegionKey` 字段
## [2.12.22] - 2021-04-28
- 更新`@netless/white-audio-plugin2`,`@netless/white-video-plugin2`插件，修复显示问题
## [2.12.21] - 2021-04-28
- 更新`@netless/white-audio-plugin` 至 1.2.23，修复回放时，音频文件显示问题。
- 支持`@netless/white-audio-plugin2`,`@netless/white-video-plugin2`插件同步支持，需要在 web 端，调用 insertPlugin 时，注册对应的 `audio2`,`video2` 。
## [2.12.20] - 2021-04-22
- 更新`white-web-sdk`至 2.12.14
## [2.12.19] - 2021-04-22
- 更新`white-web-sdk`至 2.12.13，优化动态 ppt
- 更新`@netless/iframe-bridge`至 2.0.17，优化回放时 iframe 插件逻辑
## [2.12.18] - 2021-04-20
- 更新`@netless/iframe-bridge`至 2.0.16，优化回放时 iframe 插件逻辑
## [2.12.17] - 2021-04-17
- 更新`white-web-sdk`至 2.12.12
## [2.12.16] - 2021-04-14
- 更新`@netless/iframe-bridge`至 2.0.14，优化 iframe 插件
## [2.12.15] - 2021-04-13
- 更新`@netless/iframe-bridge`至 2.0.13，优化 h5 课件消息队列
## [2.12.14] - 2021-04-13
- 更新`@netless/iframe-bridge`至 2.0.11，修复 h5 课件显示问题
## [2.12.13] - 2021-04-10
- 更新`white-web-sdk`至 2.12.9
## [2.12.12] - 2021-04-09
- 更新`@netless/iframe-bridge`至 2.0.9，修复 h5 课件显示问题
## [2.12.11] - 2021-04-09
- 更新`@netless/iframe-bridge`至 2.0.8，修复 h5 课件显示问题
## [2.12.10] - 2021-04-06
- 更新`white-web-sdk`至 2.12.8，修复 follower 视角可能无法立即同步的问题
## [2.12.9] - 2021-04-02
- 更新`white-web-sdk`至 2.12.7，优化动态 ppt 显示
## [2.12.8] - 2021-03-30
- 更新`@netless/iframe-bridge`至 2.0.7
## [2.12.7] - 2021-03-30
- 更新`white-web-sdk`至 2.12.6
## [2.12.6] - 2021-03-25
- 更新`@netless/iframe-bridge`至 2.0.5，优化回放时，H5 课件展示
## [2.12.5] - 2021-03-25
- Displayer 新增`scaleIframeToFit`API，可以将 H5 课件进行铺满操作（类似`scalePptToFit`），详情见`Displayer.h`注释
## [2.12.4] - 2021-03-24
- 更新`@netless/cursor-tool`至 0.0.7
## [2.12.3] - 2021-03-20
- 默认关闭笔锋功能，开启笔锋后的笔记，需要客户本地 sdk 支持，否则无法显示。如需打开，请参考`WhiteRoomConfig`中的`disableNewPencil`属性。
## [2.12.2] - 2021-03-15
- 更新`white-web-sdk`至 2.12.4，优化 ppt 显示逻辑
- 优化音视频插件，在回放时，不显示按钮
## [2.12.1] - 2021-03-15
- 优化使用 iframe 课件时，部分课件存在性能问题
## [2.12.0] - 2021-03-11
- `WhiteSdkConfiguration`新增`enableImgErrorCallback`参数，开启图片加载失败事件的监听，该监听，会回调`CommonCallbackDelegate`中新增的`customMessage`方法。事件内容格式，见`customMessage`中注释。
- 回放时，如果启用了 iframe 插件，自动向 iframe 发送 player 信息。
- 增加`WhiteboardView`大小变化时，自动调用`refreshViewSize`功能
## [2.11.22] - 2021-03-08
- 更新`@netless/iframe-bridge`至1.1.2
## [2.11.21] - 2021-03-05
- 更新`white-web-sdk`至 2.12.2
- 更新`@netless/white-audio-plugin@1.2.20`,`@netless/white-video-plugin@1.2.20`，优化音视频插件
- 更新`@netless/iframe-bridge`至2.1.1
- 更新`white-web-sdk`至 2.11.12,优化 ppt 显示逻辑
## [2.11.17] - 2021-02-05
- 更新`@netless/white-audio-plugin@1.2.19`,`@netless/white-video-plugin@1.2.18`，优化音视频插件进度同步
## [2.11.16] - 2021-02-05
- 更新`@netless/white-audio-plugin@1.2.17`,`@netless/white-video-plugin@1.2.16`，优化音视频插件进度同步
## [2.11.15] - 2021-01-29
- 更新`white-web-sdk`至 2.11.11，优化 ppt 中音视频处理
## [2.11.14] - 2021-01-26
- 更新`white-web-sdk`至 2.11.10，兼容部分低版本 ppt 音视频播放
## [2.11.13] - 2021-01-20
- 兼容 Xcode 10 闭源编译
## [2.11.12] - 2021-01-20
- 更新`white-web-sdk`至 2.11.9
- `WhiteDisplayerState`新增`cameraState`属性，`WhiteRoomState`与`WhitePlayerState`均可使用，具体请看`WhiteCameraState`类注释
## [2.11.11] - 2020-12-29
- 更新`white-web-sdk`至 2.11.8
- 更新`WhiteSdkConfiguration`的`loggerOptions`参数
## [2.11.9] - 2020-12-21
- 更新`@netless/iframe-bridge`至 1.0.6
## [2.11.8] - 2020-12-17
- 更新`@netless/iframe-bridge`至 1.0.5
## [2.11.7] - 2020-12-17
- 更新`@netless/iframe-bridge`至 1.0.4
## [2.11.6] - 2020-12-10
- 同步更新 web sdk 至 2.11.7
- 同步更新`@netless/combine-player`,`@netless/iframe-bridge`插件
- ppt 自定义字体现在支持默认回落字体设置。在自定义设置里，key 设置为'*','*-italic','*-bold','*-bold-italic'后， 当存在不属于自定义字体列表的常规体，斜体，粗体，粗斜体都会使用以上传入的网址字体进行加载。
## [2.11.5] - 2020-12-08
- 修复向 iframe 插件发送消息时，遇到的权限问题
## [2.11.4] - 2020-12-08
- 修复`loadFontFaces:completionHandler:`无法添加多个不同字重的字体的问题
- 新增与 iframe 插件通信 API
    1. 向 iframe 插件发送消息见 `WhiteDisplayer`中`postIframeMessage:`方法。
    2. 目前 iframe 发出的通知，sdk 会全局广播一个 NotificationName 为 `iframe`的通知，userInfo 会带有`iframe`的完整格式。
## [2.11.3] - 2020-12-03
- 同步更新 web sdk 至 2.11.6
- 优化弱网连接
- WhiteSDK 新增本地嵌入字体 API  `setupFontFaces:` `loadFontFaces:completionHandler:`，设置本地教具字体 API  `updateTextFont:`。具体使用，可以查看对应 API 代码注释，以及 Example 工程中`WhiteBaseViewController`的`insertFontFace`示例代码
## [2.11.2] - 2020-11-27
- 同步更新 web sdk 至 2.11.5
- 更新`@netless/combine-player`，优化插件逻辑
## [2.11.1] - 2020-11-18
- 优化在 web 端播放 mediaURL 的 seek 逻辑
- 修复 2.11.0 中在初始化时，立刻 seek 的问题
## [2.11.0] - 2020-11-17
- 同步更新 web sdk 至 2.11.3
- iframe 插件的使用，增加开关，并且由默认打开，更改为默认关闭（具体见 WhiteSdkConfiguration enableIFramePlugin 属性）。
- WhiteSdk 增加 isPlayable API，可以查询，对应房间，对应时间段是否存在回放数据。
- WhiteSdk 支持多数据中心，枚举可见 WhiteConsts.h 中 WhiteRegionKey 枚举，可以分别在初始化 sdk，加入实时房间，回放房间时，进行设置。默认 Region 为旧数据中心。SDK 初始化 region 参数，将会影响实时房间，回放房间默认。 region。具体见`WhiteSdkConfiguration`,`RoomParams`,`PlayerConfiguration`中`setRegion`API。
- 回放时，传入mediaURL，将由开源组件`@netless/combine-player`接管，该组件优化了音视频中有丢帧情况的播放处理。
    * 目前问题：`@netless/combine-player` 无法正确处理，在初始化时，立刻进行 seek 的行为。`@netless/combine-player` 会主动 seek 触发缓冲，无需再次手动操作。
- 回放 Player 增加 disableCameraTransform API，该功能与实时房间 room 效果一致（具体见 displayer disableCameraTransform方法）。
## [2.10.0] - 2020-10-10
- 同步更新 web sdk 至 2.10.1 版本（无断代更新内容）
- 支持显示web 端通过 iframe 插件（`@netless/iframe-bridge`）插入的 iframe 插件，类似音视频插件，native 无需进行修改，只需要更新至 2.10.0 版本即可
## [2.9.19] - 2020-09-23
- 同步 web sdk 至 2.9.17 版本
- 增加 redo undo 可以操作步数回调，具体见`WhiteRoomCallbackDelegate`协议
- 更新头像显示组件，修复没有传入 userPayload 时，无法显示的问题
## [2.9.18] - 2020-09-15
- 切换头像显示组件UI，web 端可以切换至`@netless/cursor-tool`即可保持一致，新组件支持`cursorName`，`avatar`字段。
## [2.9.17] - 2020-09-10
- 同步 web sdk 至 2.9.16 版本
- 修复部分房间，回放时音频插件内容会自动全屏的问题
- 优化 WhiteboardView，支持用户使用子类继承
## [2.9.16] - 2020-09-03
 - 同步 web sdk 至 2.9.15 版本 
## [2.9.15] - 2020-08-24
- 同步 web sdk 至 2.9.14 版本
- 添加 RTC 混音接口，具体实现，见 SDK  repo RTC 分支
## [2.9.14] - 2020-08-10
- 修复`room.phase`属性不正确，必须使用异步 API 获取的问题
- 修复 PPT 视频在播放结束后，可能变空白的问题
- 修复 `sdkSetupFail`回调检测错误的问题
- PPT 视频支持同步（需要同步使用 white-web-sdk 2.9.13）
## [2.9.13] - 2020-07-22
- 同步 web SDK 至 2.9.12
- 修复以下情况时，webView 中 SDK 初始化/启动失败，没有任何通知的问题。回调通知在 `WhiteCommonCallbackDelegate`代理中新增的`sdkSetupFail:`方法中；更多具体内容，见源码注释。
    1. 当传入非法 AppIdentifier
    2. 当获取用户配置信息失败时（例如无网络）
- 修复 webView 中 SDK 初始化失败，导致加入房间，回放房间 API 一直没有回调的问题。
## [2.9.12] - 2020-07-16
- 同步 web SDK 至 2.9.11
- 新增动态 ppt 中音视频播放暂停回调，具体见 `WhiteCommonCallbackDelegate`代理中`pptMediaPlay:``pptMediaPause:`方法及其注释
- iOS 10 及其以上设备，切换至 canvas 渲染引擎
## [2.9.11] - 2020-07-09
- 修复白板背景色 API 设置失效问题
## [2.9.10] - 2020-07-07
- 同步 web SDK 至 2.9.10
- 优化截图 API
## [2.9.9] - 2020-07-07
- 同步 web SDK 至 2.9.9
- 修复 native 端动态 PPT 翻页后媒体仍然在播放的 bug
## [2.9.8] - 2020-07-03
- 优化音视频插件
## [2.9.7] - 2020-07-02
- 优化音视频插件，修复 native 进入房间时，正在播放的音视频进度不一致
## [2.9.6] - 2020-07-01
- 修复动态 PPT 字体重复下载导致内存占用问题
## [2.9.5] - 2020-06-30
- 同步更新 white-web-sdk 至 2.9.7
- 提高 canvas 引擎兼容性
## [2.9.4] - 2020-06-25
- 同步更新 white-web-sdk 至 2.9.4 版本
- 修复`WhiteContentModeConfig`中`scale`为 0 时，实际为 1 的问题
## [2.9.3] - 2020-06-23
- 同步更新 white-web-sdk 至 2.9.3 版本
- 新增`抓手``激光笔`教（见`WhiteApplianceNameKey`）
- 橡皮教具`disableEraseImage`属性，支持中途切换（见Room `disableEraseImage:`API） 
- Room 新增`撤销`，`取消撤销`（开启该功能前，请先阅读`disableSerialization:`介绍）
- Room 提供`复制`，`粘贴`，`副本`，`删除` API，可以对选中的内容，执行上述操作（见`WhiteRoom` 执行操作 API 部分）
- RoomConfig 弃用`disableOperations`，新增`disableCameraTransform` API，与`disableDeviceInputs`搭配，可以起到同样效果。
## [2.9.2] - 2020-06-13
- 修复 userPayload 显示问题，保持与 web 端一致的显示逻辑。
## [2.9.1] - 2020-06-10
- iOS 11及其以下，画笔渲染引擎更改为 `svg`模式，兼容低版本设备。
## [2.9.0] - 2020-06-09
- 优化底层渲染系统，画笔教具渲染引擎，默认为`Canvas`，`svg`为兼容模式。
- `WhiteMemberState`新增`直线``箭头`教具。
- `WhitePlayerConfig``audioUrl`属性更改为`mediaURL`，效果不变。
- `WhiteSdkConfiguration`：
    1. 删除`zoomMinScale`,`zoomMaxScale`属性。限制视野需求，请阅读`WhiteRoomConfig`,`WhiterPlayerConfig`以及`WhiteCameraBound`相关类和 API。
    2. 移除`sdkStrategyConfig`属性。
    3. `debug`属性更改为`log`属性，效果不变。
- 移除`WhiteOriginPrefetcher`，SDK 采用更智能的链路选择，`WhiteOriginPrefetcher`类的预热结果对 SDK 不再有效果。
- `WhiteCameraBound`增加初始化方法，方便从`zoomMinScale``zoomMaxScale`迁移的用户。
- `WhiteImageInformation`类，预埋`locked`字段。
- 删除部分弃用 API
## [2.8.1] - 2020-05-22
- 修复`预热器`数据造成的 sdk 连接失败问题。2.8.0 开始，不再需要预热功能。
## [2.8.0] - 2020-05-14
- <span style="color:red;">不兼容改动</span>：SDK 初始化时，新增必须要的 APP identitier 参数（详情见 开发者文档中，查看 APP identitier 一栏）
- 开放画笔渲染引擎选项，新增 canvas 渲染模式（需要主动选择）
- 修复`isWritable=false`用户无法跟随新主播的问题
## [2.7.14] - 2020-05-14
- 动态 ppt 增加本地 scheme 支持（详情见`WhitePptParams`类，以及`WhiteSdkConfiguration` `pptParams`属性说明，注意：拦截自定义协议需要使用 iOS 11 API）
## [2.7.13] - 2020-05-07
- 修复 2.7.11 引入导致动态 ppt 中音视频无法正常播放的问题
## [2.7.12] - 2020-05-06
- 动态 ppt 视频，增加封面
## [2.7.11] - 2020-04-28
- 修复动态 ppt 中途加入，视频无法播放的问题
## [2.7.10] - 2020-04-28
- 加入房间，回放 API，兼容重复调用（房间，回放实例会以最后一次成功回调为准）
## [2.7.9] - 2020-04-20
- 添加主线程检查，并保证主线程调用
## [2.7.8] - 2020-04-16
- 修复 ppt 媒体进度条位置不对的问题
## [2.7.7] - 2020-04-16
- 修复使用 WhiteCombinePlayer 回放时，拔出耳机等行为会导致崩溃的问题
## [2.7.6] - 2020-04-16
- 修复动态 ppt 中，音频结束后无法重新播放的问题
## [2.7.5] - 2020-04-13
- 修复音频插件，播放时自动全屏的问题
## [2.7.4] - 2020-04-12
- 优化音视频插件
- 增加获取房间所有场景 API（见 WhiteDisplayer `getEntireScenes:` 方法）
## [2.7.3] - 2020-03-28
- 统一动态 ppt 粗体显示
## [2.7.2] - 2020-03-25
- 增加动态 ppt 图片加载失败的通知
## [2.7.1] - 2020-03-22
- 优化了建连速度
- 动态 PPT 修复在 iOS 下换行不正确问题
- 修复了 canvas 模式下若干显示错误
- 兼容非音视频系统用户
## [2.7.0] - 2020-03-18
- 优化动态 ppt
- 优化底层显示效率
>兼容性问题：该版本目前有一定兼容问题，接入自定义音视频插件系统的用户，可以升级（2020 年开始接入的用户，均为该版本）；未接入音视频插件的用户请勿升级。如不清楚版本，可以询问服务团队。

## [2.6.4] - 2020-03-04
- 组合播放器，增加音视频单独缓冲开始，结束回调
## [2.6.3] - 2020-03-03
- 优化只读模式
- 优化动态 ppt 音视频
- 新增`getScenePathType`API（见 WhiteDisplayer `getScenePathType:result:`方法）
- 部分类，增加带参数初始化方法
## [2.6.2] - 2020-02-23
- 优化只读模式
- 修复回放时，后半段时间回调`step`失效的问题
- 修复`throwError`回调丢失信息的问题
## [2.6.1] - 2020-02-20
- 开放视野限制 API（查看 WhiteCameraBound 类相关内容）
- 添加回放时间进度回调频率 API（详情见 WhitePlayerConfig`step`属性）
- 添加重连等待时长 API（详见 WhiteRoomConfig`timeout`属性）
- 添加`writable`只读模式（详情见 WhiteRoomConfig`writable`属性，以及 WhiteRoom `setWritable:completionHandler:`方法）
    * 修正`disableOperations:`描述为禁止操作API
- WhiteRoom 追加主动断连标记
- 修复部分情况下，清屏 API 失效的情况
## [2.6.0] - 2020-02-18
- 优化加入房间稳定性
## [2.5.11] - 2020-02-13
- 优化低版本 iOS 动态 ppt 显示
## [2.5.10] - 2020-02-10
- 修复插件系统用户，无法查看插件的问题
## [2.5.9] - 2020-02-10
- 修复头像中，教具显示异常问题
- 修复低版本 iOS 下 index db 问题
## [2.5.8] - 2020-02-03
- 修复图片替换 API
- 增加预热器功能，使用最快资源
- 增加倍速播放 API（详情见 WhitePlayer  `playbackSpeed` 属性，以及 CombinePlayer `playbackSpeed` 属性）
## [2.5.7] - 2020-01-13
- 修复支持插件系统的用户，出现无法连接的问题
## [2.5.6] - 2020-01-07
- 更新音视频插件
- 增加向后兼容可能性
- `图片替换 API 暂时失效，将在下一版本中恢复支持`
## [2.5.5] - 2019-12-31
- 优化音视频插件
- 提供多路由选项
## [2.5.4] - 2019-12-26
- 优化`CombinePlayer`
- 优化音视频插件
## [2.5.3] - 2019-12-25
- 提供显示视频，音频插件的功能（内测功能）
## [2.5.2] - 2019-12-20
- 支持动态 ppt 点击动画
- 新增铺满 ppt API （Displayer scalePptToFit)  
## [2.5.1] - 2019-12-16
- 修复新版本`refreshViewSize`失效的问题

## [2.5.0] - 2019-12-14
- 增加`NativeReplayer`模块，支持在回放白板内容的同时，同步使用系统`AVPlayer`播放视频。
- Native 端调用代码开源
- 提供视野范围限制API

>迁移：将`import <White-SDK-iOS/WhiteSDK.h>` 更改为 `import <Whiteboard/Whiteboard.h>` 即可。

# `White-SDK-iOS` 版本记录
## [2.4.19] - 2019-12-10
- 优化断线重连逻辑
- 优化iOS音视频播放

## [2.4.18] - 2019-11-27
- 兼容 iOS 9
## [2.4.17] - 2019-11-18
- 兼容 32 位 CPU（iPhone 5s 之前设备）
- 修复 disableCameraTransform 时，导致的绘制问题
## [2.4.16] - 2019-11-08
- 颜色只接受整型
## [2.4.15] - 2019-11-04
- 橡皮擦教具，增加禁止擦除图片选项（初始化房间参数配置）
- 修复 SDK 初始化时，部分传入参数不生效的问题
- 提取 Player 与 Room 共有方法，迁移进 Displayer 作为父类实例方法（refreshViewSize, convertToPointInWorld, addMagixEventListener, addHighFrequencyEventListener, removeMagixEventListener）
## [2.4.14] - 2019-10-29
- 修复了回放时首帧存在快进的问题
- 修复了文字教具在不同端使用不同字体时，造成的文字截断问题
## [2.4.13] - 2019-10-28
- 修复 [2.4.12] 造成的 iOS 9 崩溃问题
## [2.4.12] - 2019-10-25
- 增加高频自订事件回调 API（详情见 WhiteRoom 以及 WhitePlayer 中的 addHighFrequencyEventListener）
- 优化动态ppt
- 修复部分问题
## [2.4.11] - 2019-10-14
- 兼容 Xcode10
## [2.4.10] - 2019-09-20
- 优化文字排版
- 修复横竖屏切换时，视角切换行为
- 文字教具功能适配 iOS 13
## [2.4.9] - 2019-09-11
- 优化弱网连接
- 进入实时房间时，提供更多选项（禁止操作，关闭贝塞尔等）
- 修正房间背景色 API
## [2.4.8] - 2019-08-30
- 优化截图效果
## [2.4.7] - 2019-08-24
- 修复回放时，图片替换 API 失效问题
- 修复带音视频回放时，PlayerPhase 状态变化回调不及时问题
- 优化带音视频回放效果，支持重复初始化
- 优化回放同步获取状态 API
- 修正主播状态信息类型，无主播时，对应信息为空
- 修复主动断连时，无回调问题
- 修正断连回调时，出现两次断连回调
- 修复处于最大缩放比例时，双指移动异常的问题
- 更新代码注释，添加更多 nullable 注释，优化对 swift 支持
- demo 添加部分新 API 调用示例

## [2.4.6] - 2019-08-06
- 修复部分情况下，用户加入白板，无法立刻看到主播端画面的问题
## [2.4.4] - 2019-08-02
- 优化重连逻辑
## [2.4.1] - 2019-07-30
### Fixed
- 修复 iOS 上文字教具再次编辑问题

## [2.4.0] - 2019-07-24
### Add
- 增加同步获取实时房间，回放房间状态 API
- 获取在线成员时，可以同时获取各个用户的教具状态，以及透传的用户信息
- 支持同步自定义全局状态
### Fix
- 优化白板性能
- 优化橡皮擦响应范围
## [2.3.4] - 2019-07-17
### Add
- 适配服务端动态转换 API 升级
## [2.3.3] - 2019-07-12
### Add
- 优化动态 ppt 支持
- 适配服务端动态转换 API 升级
## [2.3.2] - 2019-07-06
### Add
- 支持阿里云跨域图片

## [2.3.1] - 2019-07-04
### Add
- 增加场景预览截图 API
- 增加场景封面截图 API
- 增加使用 index 切换场景 API

## [2.2.2] - 2019-07-02
### Fix
- 修复 swift 环境下调用时，回放命令失效的问题
## [2.2.0] - 2019-07-01
### Add
- 增加文档转换 API，初始化时，支持自定义动态PPT 中字体链接
- 增加动态PPT 控制 API
- 增加视角控制 API
## [2.1.2] - 2019-06-24
### Fix
- 恢复只读 API
## [2.1.2] - 2019-06-24
### Fix
- 兼容旧版本的静态 ppt 回放

## [2.1.0] - 2019-06-22
### 兼容性变化
与之前版本 API 兼容，但是无法与低版本互连，进入同一房间。
可以与 Android 2.0.0 正式版，web 2.0.0 正式版互连，无法与 Android 2.0.0-beta 以及 web 2.0.0-beta 开头的版本互连。

可以回放 2.0.0 开始的房间，但是无法进入 2.1.0 之前的房间。
>2019.06.24 前接入的客户，在升级至该版本时，请联系 SDK 团队，确认服务器指向版本。
### Fix
- 修复文字书写位置，被软键盘覆盖的情况下，键盘消失后，白板整体偏移问题。
- 增加显示版本功能

## [2.0.5] - 2019-06-16
### Fix
- 用户头像没有正确缩放
- 文字教具，键盘无法弹出问题。（开发者目前需要手动管理键盘后，WhiteboardView 中的抖动问题）

## [2.0.4] - 2019-06-03
### Add
- 回放增加自定义事件支持
### Fix
- 修复 2.0.3-ppt 多人进入房间出现报错

## [2.0.3-ppt] - 2019-06-01
- 支持与 web 端，带动态 ppt 版本连接
- 修复 2.0.0-ppt 中 pencil 的抖动问题
- 修复 2.0.0-ppt 中 replay 支持
- 恢复默认用户头像支持

## [2.0.0-ppt] - 2019-05-19
### add
- 支持与 web 端，带动态 ppt 版本连接

## [2.0.3] - 2019-04-12
### Add
- 提供自定义实现用户头像回调参数
- 提供延时 API

## [2.0.2] - 2019-04-03
### Add
- 增加用户信息传入接口
- 增加显示用户头像功能
- 增加白板外部坐标转为白板内部坐标

## [2.0.1] - 2019-03-13
### Add
- 提供清屏 API（封装 API，并非新 API），提供测试代码
- 修复 Player 的 seek 问题

## [2.0.0] - 2019-03-10
### 兼容性变化
大版本更新，与过去版本API存在部分不兼容。无法与 1.0 版本进行互联。
### Add
- 增加回放 API，并提供回放 API 示例
- 增加测试用例代码，大部分 API 可以参考测试用例
### change
- 修改 PPT 翻页 API，并修改示例代码
