# 混音

白板 SDK 的动态 ppt 中会含有大量音视频内容，当这些媒体文件通过系统发出声音时，会与终端用户使用的实时通讯 SDK 声音采集出现一定干扰，造成杂音，回音等问题。为此，我们新增使用 RTC 来播放动态音视频的混音 API。

>该文档默认开发者已经完成 RTC 集成，如果对 RTC 相关集成有疑问，请查看 [RTC](RTC.md)

## Demo 启动

demo 需要填写以下三样内容：

1. room uuid
2. room token
3. rtc 用的 rtc App ID（`AppID.swift`）

直接打开 demo，执行 build 文件，会提示开发者需要填入以上三个参数。

## 实现

1. 实现`WhiteAudioMixerBridgeDelegate`协议。
1. 使用最新 whiteboard SDK，在初始化 `WhiteSDK` 时，传入实现`audioMixerBridgeDelegate`协议的对象。
1. 在 RTC `rtcEngine:localAudioMixingStateDidChanged:errorCode:`  回调中，主动调用 `WhiteSDK`的`audioMixer`属性中`setMediaState:errorCode:`方法，告知音视频状态更新完成。

## WhiteAudioMixerBridgeDelegate 协议实现内容

当白板动态 ppt 进行播放时，会在准备播放时，主动调用 `startAudioMixing:filePath:loopback:replace:cycle`API，开发者需要在此处主动调用 RTC sdk 的混音接口。
>在 iOS sdk 中存在一种情况：当该方法失败时，rtc SDK 不会主动调用 `rtcEngine:localAudioMixingStateDidChanged:errorCode:` 所以，无法当该值为非 0 数值时，开发者需要直接在此处代码直接调用 `audioMixer`的`setMediaState:errorCode:`方法进行传递，将非零返回值传入 errorCode，stateCode 随意填写即可。

```Swift
extension VideoChatViewController: WhiteAudioMixerBridgeDelegate {
    func startAudioMixing(_ filePath: String, loopback: Bool, replace: Bool, cycle: Int) {
        // 现阶段 iOS 端 rtc 不支持对线上 mp4 文件进行混音。该类文件混音，会出现跳转失败导致混音效果消失的问题。
        // 如果是 线上 mp4 地址，请提前使用 动态 ppt 资源包下载
        // 该 filePath 路径会收到初始化 SDK 时，pptParams 中的 scheme 参数影响。请自行恢复。
        let result:Int32 = agoraKit.startAudioMixing(filePath, loopback: true, replace: false, cycle: 1)
        print("\(#function) \(filePath) \(loopback) \(replace) \(cycle) result:\(result)")
        if result != 0 {
            self.whiteSdk!.audioMixer?.setMediaState(714, errorCode: Int(result))
        }
    }

    func stopAudioMixing() {
        let result:Int32 = agoraKit.stopAudioMixing()
        print("\(#function) result:\(result)")
        if result != 0 {
            self.whiteSdk!.audioMixer?.setMediaState(0, errorCode: Int(result))
        }

    }

    func setAudioMixingPosition(_ position: Int) {
        print("position: \(position)")
        let result: Int32 = agoraKit.setAudioMixingPosition(position)
        print("\(#function) result:\(result) position: \(position)")
        if result != 0 {
            self.whiteSdk!.audioMixer?.setMediaState(0, errorCode: Int(result))
        }
    }
}

extension VideoChatViewController: AgoraRtcEngineDelegate {
    ...
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, localAudioMixingStateDidChanged state: AgoraAudioMixingStateCode, errorCode: AgoraAudioMixingErrorCode) {
        print("localAudioMixingStateDidChanged: \(state.rawValue) errorCode: \(errorCode.rawValue)")
        if let sdk = self.whiteSdk {
            sdk.audioMixer?.setMediaState(state.rawValue, errorCode: errorCode.rawValue)
        } else {
            print("sdk not init !")
        }
    }
    
    ...    
}
```

以上内容，可在`VideoChatViewController.swift`项目中进行查看。

## 混音 API 限制

rtc 目前对于线上 mp4 混音效果不佳，当进行跳转时，会出现混音消失的情况。请提前下载对应 mp4
