
import Foundation
@_implementationOnly import WebRTC

enum MediaType {
    case video
    case audio

    init(type: String) {
        switch type {
        case "video":
            self = .video
        case "audio":
            self = .audio
        default:
            self = .video
        }
    }
}

// interface
protocol MediaSource {
    var mediaTrack: RTCMediaStreamTrack { get }
}

extension MediaSource {
    public var type: MediaType {
        return MediaType(type: mediaTrack.kind)
    }
}

class AudioSource: MediaSource {
    public var mediaTrack: RTCMediaStreamTrack {
        return track
    }

    let track: RTCAudioTrack
    let source: RTCAudioSource
    init(track: RTCAudioTrack) {
        self.track = track
        self.source = track.source
    }
}

class VideoSource: MediaSource {
    public var mediaTrack: RTCMediaStreamTrack {
        return track
    }

    let track: RTCVideoTrack
    let source: RTCVideoSource
    init(track: RTCVideoTrack) {
        self.track = track
        self.source = track.source
    }
}
