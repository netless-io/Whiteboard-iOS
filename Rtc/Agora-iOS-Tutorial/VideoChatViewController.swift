//
//  VideoChatViewController.swift
//  Agora iOS Tutorial
//
//  Created by James Fang on 7/14/16.
//  Copyright © 2016 Agora.io. All rights reserved.
//

import UIKit
import AgoraRtcKit
import WebKit
import JavaScriptCore

class VideoChatViewController: UIViewController, WKNavigationDelegate {
        
    @IBOutlet weak var localVideo: UIView!
    @IBOutlet weak var remoteVideo: UIView!

    @IBOutlet weak var localVideoMutedIndicator: UIView!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var wkWebView: WKWebView!
    @IBOutlet weak var WhiteboardContianer: UIView!
    
    weak var logVC: LogViewController?
    var agoraKit: AgoraRtcEngineKit!
    var whiteSdk: WhiteSDK?
    
    var isRemoteVideoRender: Bool = true {
        didSet {
            remoteVideo.isHidden = !isRemoteVideoRender
        }
    }
    
    var isLocalVideoRender: Bool = false {
        didSet {
            localVideoMutedIndicator.isHidden = isLocalVideoRender
        }
    }
    
    var isStartCalling: Bool = true {
        didSet {
            if isStartCalling {
                micButton.isSelected = false
            }
            micButton.isHidden = !isStartCalling
            cameraButton.isHidden = !isStartCalling
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // This is our usual steps for joining
        // a channel and starting a call.
        initializeAgoraEngine()
        view.backgroundColor = .white
        setupVideo()
        setupLocalVideo()
        joinChannel()
        setupWhiteboard()
    }
    
    private func setupWhiteboard() {
        let board = WhiteBoardView()
        board.frame = self.WhiteboardContianer.bounds;
        self.WhiteboardContianer.addSubview(board)
        board.topAnchor.constraint(equalTo: self.WhiteboardContianer.topAnchor).isActive = true
        board.leftAnchor.constraint(equalTo: self.WhiteboardContianer.leftAnchor).isActive = true
        board.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        
        let config = WhiteSdkConfiguration(app: "792/uaYcRG0I7ctP9A")
        self.whiteSdk = WhiteSDK(whiteBoardView: board, config: config, commonCallbackDelegate: self, audioMixerBridgeDelegate: self)

        let roomConfig = WhiteRoomConfig(uuid: <#Room UUID#>, roomToken: <#ROOM Token#>)

        self.whiteSdk!.joinRoom(with: roomConfig, callbacks: self) { (success, room, error) in
            if ((room) != nil) {
                
            } else {
                print("join room failed \(String(describing: error))")
            }
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "EmbedLogViewController",
            let vc = segue.destination as? LogViewController {
            self.logVC = vc
        }
    }
    
    
    func initializeAgoraEngine() {
        // init AgoraRtcEngineKit
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: AppID, delegate: self)
    }

    func setupVideo() {
        // In simple use cases, we only need to enable video capturing
        // and rendering once at the initialization step.
        // Note: audio recording and playing is enabled by default.
        agoraKit.enableVideo()
        
        // Set video configuration
        // Please go to this page for detailed explanation
        // https://docs.agora.io/cn/Voice/API%20Reference/java/classio_1_1agora_1_1rtc_1_1_rtc_engine.html#af5f4de754e2c1f493096641c5c5c1d8f
        agoraKit.setVideoEncoderConfiguration(AgoraVideoEncoderConfiguration(size: AgoraVideoDimension640x360,
                                                                             frameRate: .fps15,
                                                                             bitrate: AgoraVideoBitrateStandard,
                                                                             orientationMode: .adaptative))
    }
    
    func setupLocalVideo() {
        // This is used to set a local preview.
        // The steps setting local and remote view are very similar.
        // But note that if the local user do not have a uid or do
        // not care what the uid is, he can set his uid as ZERO.
        // Our server will assign one and return the uid via the block
        // callback (joinSuccessBlock) after
        // joining the channel successfully.
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.view = localVideo
        videoCanvas.renderMode = .hidden
        agoraKit.setupLocalVideo(videoCanvas)
    }
    
    func joinChannel() {
        // Set audio route to speaker
        agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        
        // 1. Users can only see each other after they join the
        // same channel successfully using the same app id.
        // 2. One token is only valid for the channel name that
        // you use to generate this token.
        agoraKit.joinChannel(byToken: Token, channelId: "demoChannel1", info: nil, uid: 0) { [unowned self] (channel, uid, elapsed) -> Void in
            // Did join channel "demoChannel1"
            self.isLocalVideoRender = true
            self.logVC?.log(type: .info, content: "did join channel")
        }
        
        isStartCalling = true
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func leaveChannel() {
        agoraKit.leaveChannel(nil)
        isRemoteVideoRender = false
        isLocalVideoRender = false
        isStartCalling = false
        UIApplication.shared.isIdleTimerDisabled = false
        self.logVC?.log(type: .info, content: "did leave channel")
    }
    
    
    
    @IBAction func didClickHangUpButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected {
            leaveChannel()
        } else {
            joinChannel()
        }
    }
    
    @IBAction func didClickMuteButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        // mute local audio
        agoraKit.muteLocalAudioStream(sender.isSelected)
    }
    
    @IBAction func didClickSwitchCameraButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        agoraKit.switchCamera()
    }
}

extension VideoChatViewController: WhiteRoomCallbackDelegate {
    
}

extension VideoChatViewController: WhiteCommonCallbackDelegate {
    
}

extension VideoChatViewController: WhiteAudioMixerBridgeDelegate {
    func startAudioMixing(_ filePath: String, loopback: Bool, replace: Bool, cycle: Int) {
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
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("didJoinedOfUid  ")
    }
    
    // first remote video frame
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid:UInt, size:CGSize, elapsed:Int) {
        isRemoteVideoRender = true
        
        // Only one remote video view is available for this
        // tutorial. Here we check if there exists a surface
        // view tagged as this uid.
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = remoteVideo
        videoCanvas.renderMode = .hidden
        agoraKit.setupRemoteVideo(videoCanvas)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, localAudioMixingStateDidChanged state: AgoraAudioMixingStateCode, errorCode: AgoraAudioMixingErrorCode) {
        print("localAudioMixingStateDidChanged: \(state.rawValue) errorCode: \(errorCode.rawValue)")
        if let sdk = self.whiteSdk {
            sdk.audioMixer?.setMediaState(state.rawValue, errorCode: errorCode.rawValue)
        } else {
            print("sdk not init !")
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid:UInt, reason:AgoraUserOfflineReason) {
        isRemoteVideoRender = false
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted:Bool, byUid:UInt) {
        isRemoteVideoRender = !muted
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        logVC?.log(type: .warning, content: "did occur warning, code: \(warningCode.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        logVC?.log(type: .error, content: "did occur error, code: \(errorCode.rawValue)")
    }
    

}
