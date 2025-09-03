//
//  SdpUtils.swift
//  sdk
//
//  Created by cong chen on 2025/9/3.
//

import QuartzCore

class SdpUtils{
    static func extractRtpCapabilities(_ sdpObject: [String: Any]) -> [String: Any] {
        var codecsMap = [UInt8: [String: Any]]()
        var headerExtensions = [[String: Any]]()
        
        var gotAudio = false
        var gotVideo = false
        
        guard let mediaArray = sdpObject["media"] as? [[String: Any]] else {
            return [:]
        }
        
        for m in mediaArray {
            guard let kind = m["type"] as? String else { continue }
            
            if kind == "audio" {
                if gotAudio { continue }
                gotAudio = true
            } else if kind == "video" {
                if gotVideo { continue }
                gotVideo = true
            } else {
                continue
            }
            
            // Get codecs
            if let rtpArray = m["rtp"] as? [[String: Any]] {
                for rtp in rtpArray {
                    let codecName = rtp["codec"] as? String ?? ""
                    var mimeType = "\(kind)/\(codecName)"
                    
                    var codec: [String: Any] = [
                        "kind": kind,
                        "mimeType": mimeType,
                        "preferredPayloadType": rtp["payload"] ?? 0,
                        "clockRate": rtp["rate"] ?? 0,
                        "parameters": [String: Any](),
                        "rtcpFeedback": [[String: Any]]()
                    ]
                    
                    if kind == "audio" {
                        if let encodingStr = rtp["encoding"] as? String,
                           let channels = Int(encodingStr) {
                            codec["channels"] = channels
                        } else {
                            codec["channels"] = 1
                        }
                    }
                    
                    if let pt = rtp["payload"] as? UInt8 {
                        codecsMap[pt] = codec
                    } else if let pt = rtp["payload"] as? Int {
                        codecsMap[UInt8(pt)] = codec
                    }
                }
            }
            
            // Get codec parameters
            if let fmtpArray = m["fmtp"] as? [[String: Any]] {
                for fmtp in fmtpArray {
                    guard let payload = fmtp["payload"] as? Int else { continue }
                    let pt = UInt8(payload)
                    
                    let config = fmtp["config"] as? String ?? ""
                    let parameters = Parser.parseParams(config)
                    
                    if var codec = codecsMap[pt] {
                        codec["parameters"] = parameters
                        codecsMap[pt] = codec
                    }
                }
            }
            
            // Get RTCP feedback
            if let fbArray = m["rtcpFb"] as? [[String: Any]] {
                for fb in fbArray {
                    guard let payloadStr = fb["payload"] as? String,
                          let payload = Int(payloadStr) else { continue }
                    let pt = UInt8(payload)
                    
                    if var codec = codecsMap[pt] {
                        var feedback: [String: Any] = [
                            "type": fb["type"] ?? ""
                        ]
                        if let subtype = fb["subtype"] {
                            feedback["parameter"] = subtype
                        }
                        
                        var fbList = codec["rtcpFeedback"] as? [[String: Any]] ?? []
                        fbList.append(feedback)
                        codec["rtcpFeedback"] = fbList
                        codecsMap[pt] = codec
                    }
                }
            }
            
            // Get RTP header extensions
            if let extArray = m["ext"] as? [[String: Any]] {
                for ext in extArray {
                    var headerExtension: [String: Any] = [
                        "kind": kind,
                        "uri": ext["uri"] ?? "",
                        "preferredId": ext["value"] ?? 0
                    ]
                    headerExtensions.append(headerExtension)
                }
            }
        }
        
        // Final rtpCapabilities
        var rtpCapabilities: [String: Any] = [
            "headerExtensions": headerExtensions,
            "codecs": [[String: Any]](),
            "fecMechanisms": [[String: Any]]()
        ]
        
        for (_, codec) in codecsMap {
            var codecs = rtpCapabilities["codecs"] as! [[String: Any]]
            codecs.append(codec)
            rtpCapabilities["codecs"] = codecs
        }
        
        return rtpCapabilities
    }
    
    //ortc
    static func getExtendedRtpCapabilities(localCaps: [String: Any], remoteCaps: [String: Any]) -> [String: Any] {
        // TODO: validateRtpCapabilities(localCaps)
        // TODO: validateRtpCapabilities(remoteCaps)

        var extendedRtpCapabilities: [String: Any] = [
            "codecs": [[String: Any]](),
            "headerExtensions": [[String: Any]]()
        ]

        // Match media codecs and keep the order preferred by remoteCaps.
        guard let remoteCodecs = remoteCaps["codecs"] as? [[String: Any]],
              let localCodecs = localCaps["codecs"] as? [[String: Any]] else {
            return extendedRtpCapabilities
        }

        var extendedCodecs = [[String: Any]]()

        for remoteCodec in remoteCodecs {
            if isRtxCodec(remoteCodec) { continue }

            // FIX: inout 需要可变变量；并把可能的修改带出
            var matchedLocal: [String: Any]? = nil
            var modifiedRemote = remoteCodec

            for var local in localCodecs {
                var a = local
                var b = remoteCodec
                if SdpUtils.matchCodecs(aCodec: &a, bCodec: &b, strict: true, modify: true) {
                    matchedLocal = a
                    modifiedRemote = b
                    break
                }
            }

            guard let matchingLocalCodec = matchedLocal else { continue }

            var extendedCodec: [String: Any] = [
                "mimeType": matchingLocalCodec["mimeType"] ?? "",
                "kind": matchingLocalCodec["kind"] ?? "",
                "clockRate": matchingLocalCodec["clockRate"] ?? 0,
                "localPayloadType": matchingLocalCodec["preferredPayloadType"] ?? 0,
                "localRtxPayloadType": NSNull(),
                "remotePayloadType": modifiedRemote["preferredPayloadType"] ?? 0,
                "remoteRtxPayloadType": NSNull(),
                "localParameters": matchingLocalCodec["parameters"] ?? [:],
                "remoteParameters": modifiedRemote["parameters"] ?? [:],
                "rtcpFeedback": reduceRtcpFeedback(matchingLocalCodec, modifiedRemote)
            ]

            if let channels = matchingLocalCodec["channels"] {
                extendedCodec["channels"] = channels
            }

            extendedCodecs.append(extendedCodec)
        }

        // Match RTX codecs.
        for i in 0..<extendedCodecs.count {
            var extendedCodec = extendedCodecs[i]

            if let localRtx = localCodecs.first(where: {
                isRtxCodec($0) &&
                ($0["parameters"] as? [String: Any])?["apt"] as? Int ==
                (extendedCodec["localPayloadType"] as? Int)
            }),
            let remoteRtx = remoteCodecs.first(where: {
                isRtxCodec($0) &&
                ($0["parameters"] as? [String: Any])?["apt"] as? Int ==
                (extendedCodec["remotePayloadType"] as? Int)
            }) {
                extendedCodec["localRtxPayloadType"] = localRtx["preferredPayloadType"]
                extendedCodec["remoteRtxPayloadType"] = remoteRtx["preferredPayloadType"]
                extendedCodecs[i] = extendedCodec
            }
        }

        extendedRtpCapabilities["codecs"] = extendedCodecs

        // Match header extensions.
        if let remoteExts = remoteCaps["headerExtensions"] as? [[String: Any]],
           let localExts = localCaps["headerExtensions"] as? [[String: Any]] {
            var extendedExts = [[String: Any]]()

            for remoteExt in remoteExts {
                if let matchingLocalExt = localExts.first(where: { local in
                    return matchHeaderExtensions(local, remoteExt)
                }) {
                    var extendedExt: [String: Any] = [
                        "kind": remoteExt["kind"] ?? "",
                        "uri": remoteExt["uri"] ?? "",
                        "sendId": matchingLocalExt["preferredId"] ?? 0,
                        "recvId": remoteExt["preferredId"] ?? 0,
                        "encrypt": matchingLocalExt["preferredEncrypt"] ?? false
                    ]

                    if let remoteExtDirection = remoteExt["direction"] as? String {
                        switch remoteExtDirection {
                        case "sendrecv":
                            extendedExt["direction"] = "sendrecv"
                        case "recvonly":
                            extendedExt["direction"] = "sendonly"
                        case "sendonly":
                            extendedExt["direction"] = "recvonly"
                        case "inactive":
                            extendedExt["direction"] = "inactive"
                        default:
                            break
                        }
                    }

                    extendedExts.append(extendedExt)
                }
            }

            extendedRtpCapabilities["headerExtensions"] = extendedExts
        }

        return extendedRtpCapabilities
    }
    
    static func isRtxCodec(_ codec: [String: Any]) -> Bool {
        guard let mimeType = codec["mimeType"] as? String else { return false }
        let lower = mimeType.lowercased()
        return lower == "audio/rtx" || lower == "video/rtx"
    }

    static func matchCodecs(aCodec: inout [String: Any], bCodec: inout [String: Any], strict: Bool, modify: Bool) -> Bool {
        // 1. 检查 mimeType
        guard let aMimeTypeRaw = aCodec["mimeType"] as? String,
              let bMimeTypeRaw = bCodec["mimeType"] as? String else {
            return false
        }

        let aMimeType = aMimeTypeRaw.lowercased()
        let bMimeType = bMimeTypeRaw.lowercased()
        if aMimeType != bMimeType { return false }

        // 2. 检查 clockRate
        let aClockRate = aCodec["clockRate"] as? Int ?? 0
        let bClockRate = bCodec["clockRate"] as? Int ?? 0
        if aClockRate != bClockRate { return false }

        // 3. 检查 channels
        let aHasChannels = aCodec["channels"] != nil
        let bHasChannels = bCodec["channels"] != nil
        if aHasChannels != bHasChannels { return false }
        if aHasChannels, let aCh = aCodec["channels"] as? Int, let bCh = bCodec["channels"] as? Int {
            if aCh != bCh { return false }
        }

        // 4. H264 参数检查
        if aMimeType == "video/h264" && strict {
            let aParams = aCodec["parameters"] as? [String: String] ?? [:]
            let bParams = bCodec["parameters"] as? [String: String] ?? [:]

            let aPacketizationMode = aParams["packetization-mode"].flatMap { Int($0) } ?? 0
            let bPacketizationMode = bParams["packetization-mode"].flatMap { Int($0) } ?? 0
            if aPacketizationMode != bPacketizationMode { return false }

            let aProfile = parseSdpProfileLevelId(aParams)
            let bProfile = parseSdpProfileLevelId(bParams)

            if aProfile.profile != bProfile.profile { return false }

            do {
                // 生成 answer 用的 profile-level-id
                if modify {
                    let profileLevelIdAnswer = try generateProfileLevelIdStringForAnswer(localParams: aParams, remoteParams: bParams)
                    if var aParams = aCodec["parameters"] as? [String: Any],
                       var bParams = bCodec["parameters"] as? [String: Any] {
                        aParams["profile-level-id"] = profileLevelIdAnswer
                        bParams["profile-level-id"] = profileLevelIdAnswer

                        // 再写回 aCodec 和 bCodec
                        aCodec["parameters"] = aParams
                        bCodec["parameters"] = bParams
                    }

                }
            } catch {
                return false
            }
        }

        // 5. VP9 参数检查
        else if aMimeType == "video/vp9" && strict {
            let aProfileId = aCodec["parameters"] as? [String: String]
            let bProfileId = bCodec["parameters"] as? [String: String]
            let aP = aProfileId?["profile-id"] ?? "0"
            let bP = bProfileId?["profile-id"] ?? "0"
            if aP != bP { return false }
        }

        return true
    }
    
    
    static func matchHeaderExtensions(_ aExt: [String: Any], _ bExt: [String: Any]) -> Bool {
        if let kindA = aExt["kind"] as? String,
           let kindB = bExt["kind"] as? String,
           kindA != kindB {
            return false
        }
        return (aExt["uri"] as? String) == (bExt["uri"] as? String)
    }

    static func reduceRtcpFeedback(_ codecA: [String: Any], _ codecB: [String: Any]) -> [[String: Any]] {
        var reduced = [[String: Any]]()

        guard let fbA = codecA["rtcpFeedback"] as? [[String: Any]],
              let fbB = codecB["rtcpFeedback"] as? [[String: Any]] else {
            return reduced
        }

        for aFb in fbA {
            if let typeA = aFb["type"] as? String,
               let paramA = aFb["parameter"] as? String? {
                if fbB.contains(where: { bFb in
                    (bFb["type"] as? String) == typeA &&
                    (bFb["parameter"] as? String?) == paramA
                }) {
                    reduced.append(aFb)
                }
            }
        }

        return reduced
    }
    
    static func getH264PacketizationMode(_ codec: [String: Any]) -> UInt8 {
        guard let parameters = codec["parameters"] as? [String: Any],
              let value = parameters["packetization-mode"] as? Int else {
            return 0
        }
        return UInt8(value)
    }

    static func getH264LevelAssimetryAllowed(_ codec: [String: Any]) -> UInt8 {
        guard let parameters = codec["parameters"] as? [String: Any],
              let value = parameters["level-asymmetry-allowed"] as? Int else {
            return 0
        }
        return UInt8(value)
    }

    static func getH264ProfileLevelId(_ codec: [String: Any]) -> String {
        guard let parameters = codec["parameters"] as? [String: Any],
              let value = parameters["profile-level-id"] else {
            return ""
        }

        if let intValue = value as? Int {
            return String(intValue)
        } else if let stringValue = value as? String {
            return stringValue
        } else {
            return ""
        }
    }

    static func getVP9ProfileId(_ codec: [String: Any]) -> String {
        guard let parameters = codec["parameters"] as? [String: Any],
              let value = parameters["profile-id"] else {
            return "0"
        }

        if let intValue = value as? Int {
            return String(intValue)
        } else if let stringValue = value as? String {
            return stringValue
        } else {
            return "0"
        }
    }
    
    static func getRecvRtpCapabilities(_ extendedRtpCapabilities: [String: Any]) -> [String: Any] {
        var rtpCapabilities: [String: Any] = [
            "codecs": [[String: Any]](),
            "headerExtensions": [[String: Any]]()
        ]
        
        // 处理 codecs
        if let extendedCodecs = extendedRtpCapabilities["codecs"] as? [[String: Any]] {
            var codecs: [[String: Any]] = []
            for extendedCodec in extendedCodecs {
                var codec: [String: Any] = [
                    "mimeType": extendedCodec["mimeType"] ?? "",
                    "kind": extendedCodec["kind"] ?? "",
                    "preferredPayloadType": extendedCodec["remotePayloadType"] ?? 0,
                    "clockRate": extendedCodec["clockRate"] ?? 0,
                    "parameters": extendedCodec["localParameters"] ?? [:],
                    "rtcpFeedback": extendedCodec["rtcpFeedback"] ?? []
                ]
                
                if let channels = extendedCodec["channels"] {
                    codec["channels"] = channels
                }
                
                codecs.append(codec)
                
                // 添加 RTX codec
                if let remoteRtx = extendedCodec["remoteRtxPayloadType"] {
                    let mimeType = "\(extendedCodec["kind"] ?? "")/rtx"
                    let rtxCodec: [String: Any] = [
                        "mimeType": mimeType,
                        "kind": extendedCodec["kind"] ?? "",
                        "preferredPayloadType": remoteRtx,
                        "clockRate": extendedCodec["clockRate"] ?? 0,
                        "parameters": [
                            "apt": extendedCodec["remotePayloadType"] ?? 0
                        ],
                        "rtcpFeedback": [[String: Any]]()
                    ]
                    codecs.append(rtxCodec)
                }
            }
            rtpCapabilities["codecs"] = codecs
        }
        
        // 处理 headerExtensions
        if let extendedExtensions = extendedRtpCapabilities["headerExtensions"] as? [[String: Any]] {
            var exts: [[String: Any]] = []
            for extendedExtension in extendedExtensions {
                guard let direction = extendedExtension["direction"] as? String,
                      direction == "sendrecv" || direction == "recvonly" else { continue }
                
                let ext: [String: Any] = [
                    "kind": extendedExtension["kind"] ?? "",
                    "uri": extendedExtension["uri"] ?? "",
                    "preferredId": extendedExtension["recvId"] ?? 0,
                    "preferredEncrypt": extendedExtension["encrypt"] ?? false,
                    "direction": direction
                ]
                exts.append(ext)
            }
            rtpCapabilities["headerExtensions"] = exts
        }
        
        return rtpCapabilities
    }


}
