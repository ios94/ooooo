//
//  BackgroundAudioManager.swift
//  AshteMobile
//
//  Created by Nagata Asami on 12/10/25.
//

import AVFoundation

class BackgroundAudioManager {
    static let shared = BackgroundAudioManager()
    private let _engine = AVAudioEngine()
    private var _isRunning = false
    

    private init() {}

    func start() {
		guard !_isRunning else { return }
        do {
            let session = AVAudioSession.sharedInstance()

            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
            let silence = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
                let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
                for buffer in ablPointer {
                    memset(buffer.mData, 0, Int(buffer.mDataByteSize))
                }
                return noErr
            }

            _engine.attach(silence)
            _engine.connect(silence, to: _engine.mainMixerNode, format: nil)
            try _engine.start()
			_isRunning = true
        } catch {
            print("failed to start engine:", error)
        }
    }

    func stop() {
		guard _isRunning else { return }
        _engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
		_isRunning = false
    }
}
