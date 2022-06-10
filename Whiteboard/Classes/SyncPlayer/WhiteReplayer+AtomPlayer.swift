//
//  WhiteReplayer+AtomPlayer.swift
//  SyncPlayer_Example
//
//  Created by xuyunshi on 2022/6/2.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SyncPlayer

private var proxyKey: String?
private var atomStatusKey: String?
private var atomErrorKey: String?
private var atomListenersKey: String?
private let statusKey = "status"
private let bufferKeepUpKey = "playbackLikelyToKeepUp"
private let bufferFullKey = "playbackBufferFull"
private let bufferEmptyKey = "playbackBufferEmpty"

class WhitePlayerEventProxy: WhiteProxy, WhitePlayerEventDelegate {}

extension WhitePlayerEvent {
    var proxy: WhitePlayerEventProxy? {
        get {
            objc_getAssociatedObject(self, &proxyKey) as? WhitePlayerEventProxy
        }
        set {
            objc_setAssociatedObject(self, &proxyKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc
    func hook_setDelegate(_ delegate: WhitePlayerEventDelegate?) {
        let proxy = WhitePlayerEventProxy.target(delegate, middleMan: nil)
        hook_setDelegate(proxy)
        self.proxy = proxy
    }
}

extension WhitePlayer: AtomPlayer {
    var proxy: WhitePlayerEventProxy? {
        let bridge = value(forKey: "bridge") as? WhiteBoardView
        let playerEvent = bridge?.value(forKey: "playerEvent") as? WhitePlayerEvent
        if playerEvent?.delegate == nil {
            // trigger hook once
            playerEvent?.delegate = nil
        }
        return playerEvent?.proxy
    }
    
    public func atomSetup() {
        proxy?.middleMan = self
    }
    
    public func atomDestroy() {
        proxy?.middleMan = nil
    }
    
    public var atomStatus: AtomPlayStatus {
        get {
            (objc_getAssociatedObject(self, &atomStatusKey) as? AtomPlayStatus) ?? .ready
        }
        set {
            guard newValue != atomStatus else { return }
            objc_setAssociatedObject(self, &atomStatusKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            listeners.forEach { $0.value(newValue) }
        }
    }

    var listeners: [Int: ((AtomPlayStatus) -> Void)] {
        get {
            (objc_getAssociatedObject(self, &atomListenersKey) as? [Int: ((AtomPlayStatus) -> Void)]) ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &atomListenersKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    public var atomError: Error? {
        get {
            (objc_getAssociatedObject(self, &atomErrorKey) as? Error)
        }
        set {
            objc_setAssociatedObject(self, &atomErrorKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    public var readyToPlay: Bool {
        phase == .playing || phase == .pause
    }

    public var atomPlaybackRate: Float {
        get {
            Float(playbackSpeed)
        }
        set {
            playbackSpeed = CGFloat(newValue)
        }
    }

    public func atomPlay() {
        play()
        if readyToPlay {
            atomStatus = .playing
        } else {
            atomStatus = .buffering
        }
    }

    public func atomPause() {
        atomStatus = .pause
        pause()
    }

    public func atomReady() {
        atomStatus = .ready
        pause()
    }

    public func atomCurrentTime() -> CMTime {
        .init(seconds: timeInfo.scheduleTime * 1000, preferredTimescale: 1000)
    }

    public func atomDuration() -> CMTime {
        .init(seconds: timeInfo.timeDuration, preferredTimescale: 1000)
    }

    public func atomSeek(time: CMTime) {
        atomSeek(time: time, { _ in })
    }

    public func atomSeek(time: CMTime, _ completionHandler: @escaping ((Bool) -> Void)) {
        seek(toScheduleTime: time.seconds) { result in
            switch result {
            case .success:
                completionHandler(true)
            case .successButUnnecessary:
                completionHandler(false)
            case .override:
                completionHandler(false)
            case .stopped:
                completionHandler(false)
            default:
                completionHandler(false)
            }
        }
    }

    @discardableResult
    public func addStatusListener(_ listener: @escaping ((AtomPlayStatus) -> Void)) -> AtomListener {
        let index = listeners.keys.max().map { $0 + 1 } ?? 0
        listeners[index] = listener
        listener(atomStatus)
        return AnyAtomListener { [weak self] in
            guard let self = self,
                    let removeIndex = self.listeners.index(forKey: index) else { return }
            self.listeners.remove(at: removeIndex)
        }
    }
}

extension WhitePlayer: WhitePlayerEventDelegate {
    public func phaseChanged(_ phase: WhitePlayerPhase) {
        switch phase {
        case .buffering, .waitingFirstFrame:
            // Upload buffering when playing
            if atomStatus == .playing {
                atomStatus = .buffering
            }
        case .playing:
            // Playing from buffering
            if atomStatus == .buffering {
                atomStatus = .playing
            }
        case .pause:
            return
        case .stopped:
            return
        case .ended:
            atomStatus = .ended
        }
    }
    
    public func error(whenRender error: Error) {
        atomError = error
        atomStatus = .error
    }
    
    public func error(whenAppendFrame error: Error) {
        atomError = error
        atomStatus = .error
    }
    
    public func stoppedWithError(_ error: Error) {
        atomError = error
        atomStatus = .error
    }
}
