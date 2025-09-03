//
//  Handler.swift
//  sdk
//
//  Created by cong chen on 2025/9/1.
//

@_implementationOnly import WebRTC

class Handler: NSObject,RTCPeerConnectionDelegate{
    
    
    func getNativeRtpCapabilities () async -> [String: Any]{
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let factory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
        
        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan;
        config.bundlePolicy = .maxBundle
        let constraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
        let pc = factory.peerConnection(with: config, constraints: constraints, delegate: self)
        
        pc!.addTransceiver(of: RTCRtpMediaType.audio)
        pc!.addTransceiver(of: RTCRtpMediaType.video)
        
        let constraints2 = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)

        let sdp = try! await pc!.offer(for: constraints2)
//        print(sdp.description)
        let session = Parser.parse(sdp.description)
//        print("session \(session.toJSONString()!)")
        let nativeRtpCapabilities = SdpUtils.extractRtpCapabilities(session)
        
        return nativeRtpCapabilities
    }
    
    //
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
            
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
    
}
