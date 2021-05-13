声网通过全球部署的虚拟网络，提供可以灵活搭配的 API 组合，提供稳定可靠、功能丰富的实时互动白板。

- [WhiteSDK](WhiteSDK) 类提供初始化互动白板 SDK、加入互动白板实时房间、创建白板回放的主要方法。
- [WhiteRoom](WhiteRoom) 类提供管理互动白板实时房间的方法。
- [WhitePlayer](WhitePlayer) 类提供控制白板回放的方法。
- [WhiteDisplayer](WhiteDisplayer) 类为 [WhitePlayer](WhitePlayer) 类和 [WhiteRoom](WhiteRoom) 类的父类。[WhitePlayer](WhitePlayer) 和 [WhiteRoom](WhiteRoom) 的对象都可以调用该类中的方法。



### SDK 初始化

| 方法                                                       | 描述                          |
| :----------------------------------------------------------- | :------------------------------ |
| [initWithWhiteBoardView]([WhiteSDK initWithWhiteBoardView:config:commonCallbackDelegate:])1| 初始化白板界面（设置回调）  |
| [initWithWhiteBoardView]([WhiteSDK initWithWhiteBoardView:config:commonCallbackDelegate:audioMixerBridgeDelegate:])2| 初始化白板界面（设置回调和混音） |
| [WhiteCommonCallbacks](WhiteCommonCallbacks)  | 设置通用事件回调 |
| [joinRoomWithConfig]([WhiteSDK joinRoomWithConfig:callbacks:completionHandler:])  | 设置房间参数和房间事件回调并加入互动白板实时房间 |
| [joinRoomWithUuid]([WhiteSDK joinRoomWithUuid:roomToken:completionHandler:])   | 设置房间 UUID 和 Room Token 并加入互动白板实时房间 |
| [createReplayerWithConfig]([WhiteSDK createReplayerWithConfig:callbacks:completionHandler:])   | 创建互动白板回放房间 |
| [isPlayable]([WhiteSDK isPlayable:result:])    | 查看房间是否有回放数据 |
| [setupFontFaces]([WhiteSDK setupFontFaces:])   | 声明在本地白板中可用的字体 |
| [loadFontFaces]([WhiteSDK loadFontFaces:completionHandler:]) | 声明并预加载在本地白板中可用的字体 |
| [updateTextFont]([WhiteSDK updateTextFont:])  | 设置在本地白板中输入文字时使用的字体 |


### 通用事件

| 事件                                                       | 描述                          |
| :----------------------------------------------------------- | :------------------------------ |
| [throwError]([WhiteCommonCallbackDelegate throwError:])   | 出现未捕获的全局错误回调 |
| [urlInterrupter]([WhiteCommonCallbackDelegate urlInterrupter:]) | 拦截图片 URL 回调 |
| [pptMediaPlay]([WhiteCommonCallbackDelegate pptMediaPlay])    | 动态 PPT 中的音视频开始播放回调 |
| [pptMediaPause]([WhiteCommonCallbackDelegate pptMediaPause])  | 动态 PPT 中的音视频赞同播放回调 |
| [customMessage]([WhiteCommonCallbackDelegate customMessage:])  | 接收到网页发送的消息回调 |
| [sdkSetupFail]([WhiteCommonCallbackDelegate sdkSetupFail:])   | SDK 初始化失败回调 |



### 实时房间管理

| 方法                                                      | 描述                          |
| :----------------------------------------------------------- | :------------------------------ |
| [observerId]([WhiteRoom observerId])   | 获取用户 ID |
| [setWritable]([WhiteRoom setWritable:completionHandler:]) | 设置用户是否为互动模式 |
| [disableDeviceInputs]([WhiteRoom disableDeviceInputs:]) | 禁止/允许用户操作工具 |
| [disconnect]([WhiteRoom disconnect:])   | 断开连接 |
| [setGlobalState]([WhiteRoom setGlobalState:])   | 修改房间的全局状态 |
| [disconnectedBySelf]([WhiteRoom disconnectedBySelf])   | 获取用户是否主动断开连接 |
| [writable]([WhiteRoom writable]) | 获取用户是否为互动模式 |
| [globalState]([WhiteRoom globalState])| 获取房间的全局状态（同步方法） |
| [getGlobalStateWithResult]([WhiteRoom getGlobalStateWithResult:]) | 获取房间的全局状态（异步方法） |
| [roomMembers]([WhiteRoom roomMembers])| 获取房间的用户列表（同步方法） |
| [getRoomMembersWithResult]([WhiteRoom getRoomMembersWithResult:])| 获取房间的用户列表（异步方法） |
| [phase]([WhiteRoom phase])  | 获取房间的连接状态（同步方法） |
| [getRoomPhaseWithResult](getRoomPhaseWithResult:) | 获取房间的连接状态（异步方法） |
| [state]([WhiteRoom state])| 获取房间的所有状态（同步方法） |
| [getRoomStateWithResult]([WhiteRoom getRoomStateWithResult:])| 获取房间的所有状态（异步方法） |


### 白板工具设置

| 方法                                                      | 描述                          |
| :----------------------------------------------------------- | :------------------------------ |
| [setMemberState]([WhiteRoom setMemberState:])  | 修改房间的白板工具状态 |
| [memberState]([WhiteRoom memberState])  | 获取白板工具状态（同步方法） |
| [getMemberStateWithResult]([WhiteRoom getMemberStateWithResult:]) | 获取白板工具状态（异步方法） |
| [copy]([WhiteRoom copy])  | 复制选中内容 |
| [paste]([WhiteRoom paste]) | 粘贴复制的内容 |
| [duplicate]([WhiteRoom duplicate])  | 复制并粘贴选中的内容 |
| [deleteOpertion](deleteOpertion) | 删除选中的内容 |
| [disableSerialization]([WhiteRoom disableSerialization:]) | 开启/禁止本地序列化 |
| [redo]([WhiteRoom redo])   | 重做 |
| [undo]([WhiteRoom undo]) | 撤销上一步操作 |
| [disableEraseImage]([WhiteRoom disableEraseImage:]) | 关闭/开启橡皮擦擦除图片功能 |
| [disableDeviceInputs]([WhiteRoom disableDeviceInputs:])  | 禁止/允许用户操作白板工具 |

### 视角操作

| 方法                                                      | 描述                          |
| :----------------------------------------------------------- | :------------------------------ |
| [setViewMode]([WhiteRoom setViewMode:]) |  切换视角模式|
| [setCameraBound]([WhiteDisplayer setCameraBound:])| 设置视角边界 |
| [disableCameraTransform]([WhiteDisplayer disableCameraTransform:])| 禁止/允许用户调整视角 |
| [moveCamera]([WhiteDisplayer moveCamera:])  |调整视角|
| [moveCameraToContainer]([WhiteDisplayer moveCameraToContainer:])| 调整视角以完整显示视觉矩形中的内容 |
| [scalePptToFit]([WhiteDisplayer scalePptToFit:]) | 调整视角以完整显示 PPT 的内容|
| [disableCameraTransform]([WhiteRoom disableCameraTransform:]) | 禁止/允许用户调整（移动或缩放）视角 |
| [broadcastState]([WhiteRoom broadcastState])| 获取用户的视角状态（同步方法） |
| [getBroadcastStateWithResult]([WhiteRoom getBroadcastStateWithResult:])| 获取用户的视角状态（异步方法） |


### 场景管理

| 方法                                                      | 描述                          |
| :----------------------------------------------------------- | :------------------------------ |
| [insertImage]([WhiteRoom insertImage:])| 插入图片显示区域 |
| [completeImageUploadWithUuid]([WhiteRoom completeImageUploadWithUuid:src:])| 展示图片|
| [insertImage]([WhiteRoom insertImage:src:])|插入并展示图片 |
| [sceneState]([WhiteRoom sceneState])| 获取当前场景组下的场景状态（同步方法）|
| [getSceneStateWithResult]([WhiteRoom getSceneStateWithResult:])| 获取当前场景组下的场景状态（异步方法）|
| [getScenesWithResult]([WhiteRoom getScenesWithResult:])| 获取当前场景组下的场景列表|
| [setScenePath]([WhiteRoom setScenePath:])|切换至指定的场景（同步方法） |
| [setScenePath]([WhiteRoom setScenePath:completionHandler:]) |切换至指定的场景（异步方法） |
| [setSceneIndex]([WhiteRoom setSceneIndex:completionHandler:])| 切换至当前场景组下的指定场景|
| [putScenes]([WhiteRoom putScenes:scenes:index:])| 在指定场景组下插入多个场景|
| [moveScene]([WhiteRoom moveScene:target:])|移动场景 |
| [removeScenes]([WhiteRoom removeScenes:])|删除场景或者场景组 |
| [cleanScene]([WhiteRoom cleanScene:])|清除当前场景的所有内容 |
| [pptNextStep]([WhiteRoom pptNextStep])|播放动态 PPT 下一页 |
| [pptPreviousStep]([WhiteRoom pptPreviousStep])|返回动态 PPT 上一页|
| [getScenePathType]([WhiteDisplayer getScenePathType:result:])|查询场景路径类型 |
| [getEntireScenes]([WhiteDisplayer getEntireScenes:])|获取当前房间内所有场景的信息 |
| [getScenePreviewImage]([WhiteDisplayer getScenePreviewImage:completion:])| 获取指定场景的预览图|
| [getSceneSnapshotImage]([WhiteDisplayer getSceneSnapshotImage:completion:])| 获取指定场景的截图|

### 回放管理

| 方法                                                       | 描述                          |
| :----------------------------------------------------------- | :------------------------------ |
| [play]([WhitePlayer play])  | 开始白板回放 |
| [pause]([WhitePlayer pause]) | 暂停白板回放 |
| [stop]([WhitePlayer stop])   | 停止白板回放|
| [seekToScheduleTime]([WhitePlayer seekToScheduleTime:])  | 设置白板回放的播放位置 |
| [setObserverMode]([WhitePlayer setObserverMode:]) | 设置白板回放的查看模式 |
| [playbackSpeed]([WhitePlayer playbackSpeed])  | 获取白板回放的倍速（同步方法）|
| [getPlaybackSpeed]([WhitePlayer getPlaybackSpeed:])    |获取白板回放的倍速（异步方法）|
| [phase]([WhitePlayer phase])  | 获取白板回放的阶段（同步方法）|
| [getPhaseWithResult]([WhitePlayer getPhaseWithResult:])  | 获取白板回放的阶段（异步方法）|
| [state]([WhitePlayer state])  | 获取白板回放的状态（同步方法）|
| [getPlayerStateWithResult]([WhitePlayer getPlayerStateWithResult:])  | 获取白板回放的状态（异步方法）|
| [timeInfo]([WhitePlayer timeInfo])  | 获取白板回放的时间信息（同步方法）|
| [getPlayerTimeInfoWithResult]([WhitePlayer getPlayerTimeInfoWithResult:])  | 获取白板回放的时间信息（异步方法）|


### 自定义事件

| 事件                                                       | 描述                          |
| :----------------------------------------------------------- | :------------------------------ |
| [dispatchMagixEvent]([WhiteRoom dispatchMagixEvent:payload:])  | 发送自定义事件 |
| [addMagixEventListener]([WhiteDisplayer addMagixEventListener:]) | 注册自定义事件监听 |
| [addHighFrequencyEventListener]([WhiteDisplayer addHighFrequencyEventListener:fireInterval:])   | 注册高频自定义事件监听 |
| [removeMagixEventListener]([WhiteDisplayer removeMagixEventListener:])   | 移除自定义事件监听 |


### iframe 插件交互

| 方法                                                       | 描述                          |
| :----------------------------------------------------------- | :------------------------------ |
| [postIframeMessage]([WhiteDisplayer postIframeMessage:])  | 向 iframe 插件发送 key-value 格式的信息 |
| [setTimeDelay]([WhiteRoom setTimeDelay:]) | 拦截图片 URL 回调 |


### 其他方法

| 方法                                                       | 描述                          |
| :----------------------------------------------------------- | :------------------------------ |
| [debugInfo]([WhiteRoom debugInfo:])  | 获取调试日志信息 |
| [setTimeDelay]([WhiteRoom setTimeDelay:])  | 拦截图片 URL 回调 |
| [convertToPointInWorld]([WhiteDisplayer convertToPointInWorld:result:])    | 转换白板上点的坐标 |
| [refreshViewSize]([WhiteDisplayer refreshViewSize])   | 刷新白板的界面 |