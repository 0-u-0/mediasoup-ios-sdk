//
//  Device.swift
//  sdk
//
//  Created by cong chen on 2025/9/1.
//

@_implementationOnly import WebRTC

class Device {
    
    func load(routerRtpCapabilities: [String: AnyCodable]) async {
        //TODO: cc
        //1. check if is_load
        //2. ortc::validateRtpCapabilities(routerRtpCapabilities);
        let handler = Handler()
        await handler.getNativeRtpCapabilities()
    }
}
