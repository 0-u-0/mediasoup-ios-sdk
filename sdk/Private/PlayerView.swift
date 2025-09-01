

import Foundation

@_implementationOnly import WebRTC

internal class PlayerView: RTCVideoViewDelegate {
    var view: RTCMTLVideoView


    init() {
        view = RTCMTLVideoView(frame: .zero)
        view.videoContentMode = .scaleAspectFill  // Maintains aspect ratio
        view.clipsToBounds = true
        view.delegate = self
    }
    
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        //TODO: save size
        print("size \(size.width),\(size.height)")

    }
}

