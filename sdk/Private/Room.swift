//
//  Room.swift
//  MediasoupExample
//
//  Created by weidian on 2025/3/10.
//
import Foundation
@_implementationOnly import WebRTC



protocol RoomDelegate: AnyObject {
    func onRoomConnected()
    func onRoomDisconnected()
    
    func onUserJoin(_ userId:String,_ userName:String)
    func onUserLeave(_ userId:String,_ userName:String)
    func onUserStreamChange(_ userId:String,_ userName:String,_ kind:String,_ isEnable:Bool)
    func onUserStreamMute(_ userId:String,_ userName:String,_ kind:String,_ isMute:Bool)
}


internal class Room{
    
    
    private var factory = RTCPeerConnectionFactory()

    private let webSocketQueue = DispatchQueue(label: "WebSocketQueue")
    private let pcQueue = DispatchQueue(label: "PC")
    

    private var localAudioSource:LocalAudioSource?
    private var localVideoSource:LocalVideoSource?
    
    //
    weak var delegate:RoomDelegate?

    private let device = Device()

    
    func connect(){

        let url = URL(string: "ws://198.18.0.1:4443?roomId=dev&peerId=abc")!
        let transport = ProtooTransport(url: url)
        let peer = ProtooPeer(transport: transport)

        peer.onOpen = {
            print("Connected!")
            peer.request(method: "getRouterRtpCapabilities", data: [:]) { result in
                switch result {
                case .success(let data):
                    print("Response data:", data)
                case .failure(let error):
                    print("Request failed:", error)
                }
            }
        }

        peer.onNotification = { notification in
            print("Received notification:", notification)
        }

        peer.connect()

    }
    
    
    
    func stream(){
        pcQueue.async { [self] in
            localAudioSource = createAudioSource()
            localVideoSource = createVideoSource()
            let format = Format(width: 480, height: 640, fps: 15)
            localVideoSource?.capture(position: .front, format: format)
        }
    }
    
    func releaseStream(){
        pcQueue.async { [self] in
            localVideoSource?.release()
        }
    }
    


    func playLocal(player:Player){
        pcQueue.async { [self] in
            if let localVideoSource = localVideoSource {
                localVideoSource.play(player: player)
            }
        }
    }
    
    
    func createVideoSource() -> LocalVideoSource? {
        let rtcSource = factory.videoSource()
        let videoTrack = factory.videoTrack(with: rtcSource, trackId: "video")
        return LocalVideoSource(track: videoTrack)
    }
    
    func createAudioSource() -> LocalAudioSource? {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let rtcAudioSource = factory.audioSource(with: constraints)
        let audioTrack = factory.audioTrack(with: rtcAudioSource, trackId: "audio")
        return LocalAudioSource(track: audioTrack)
    }
    
        
}

