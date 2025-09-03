//
//  H264ProfileLevelId.swift
//  sdk
//
//  Created by cong chen on 2025/9/3.
//

import Foundation

enum H264Profile: Int {
    case constrainedBaseline = 1, baseline, main, constrainedHigh, high, predictiveHigh444
}

enum H264Level: Int, Comparable {
    case L1_b = 0, L1 = 10, L1_1 = 11, L1_2 = 12, L1_3 = 13, L2 = 20, L2_1 = 21, L2_2 = 22,
         L3 = 30, L3_1 = 31, L3_2 = 32, L4 = 40, L4_1 = 41, L4_2 = 42, L5 = 50, L5_1 = 51, L5_2 = 52
    
    static func < (lhs: H264Level, rhs: H264Level) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
}

struct H264ProfileLevelId {
    let profile: H264Profile
    let level: H264Level
}

struct H264BitPattern {
    let mask: Int
    let maskedValue: Int

    init(_ str: String) {
        func byteMaskString(_ c: Character, _ str: String) -> Int {
            var res = 0
            for i in 0..<8 {
                if str[str.index(str.startIndex, offsetBy: i)] == c {
                    res |= (1 << (7 - i))
                }
            }
            return res
        }
        self.maskedValue = byteMaskString("1", str)
        self.mask = ~byteMaskString("x", str)
    }

    func isMatch(_ value: Int) -> Bool {
        return maskedValue == (value & mask)
    }
}

struct H264ProfilePattern {
    let profileIdc: Int
    let profileIop: H264BitPattern
    let profile: H264Profile
}

// 预定义 pattern
let profilePatterns: [H264ProfilePattern] = [
    H264ProfilePattern(profileIdc: 0x42, profileIop: H264BitPattern("x1xx0000"), profile: .constrainedBaseline),
    H264ProfilePattern(profileIdc: 0x4D, profileIop: H264BitPattern("1xxx0000"), profile: .constrainedBaseline),
    H264ProfilePattern(profileIdc: 0x58, profileIop: H264BitPattern("11xx0000"), profile: .constrainedBaseline),
    H264ProfilePattern(profileIdc: 0x42, profileIop: H264BitPattern("x0xx0000"), profile: .baseline),
    H264ProfilePattern(profileIdc: 0x58, profileIop: H264BitPattern("10xx0000"), profile: .baseline),
    H264ProfilePattern(profileIdc: 0x4D, profileIop: H264BitPattern("0x0x0000"), profile: .main),
    H264ProfilePattern(profileIdc: 0x64, profileIop: H264BitPattern("00000000"), profile: .high),
    H264ProfilePattern(profileIdc: 0x64, profileIop: H264BitPattern("00001100"), profile: .constrainedHigh),
    H264ProfilePattern(profileIdc: 0xF4, profileIop: H264BitPattern("00000000"), profile: .predictiveHigh444)
]

let defaultProfileLevelId = H264ProfileLevelId(profile: .constrainedBaseline, level: .L3_1)

func parseSdpProfileLevelId(_ params: [String: String]?) -> H264ProfileLevelId {
    guard let params = params else {
        return defaultProfileLevelId
    }

    if let profileLevelIdStr = params["profile-level-id"],
       let parsed = parseProfileLevelId(profileLevelIdStr) {
        return parsed
    } else {
        return defaultProfileLevelId
    }
}

func parseProfileLevelId(_ str: String?) -> H264ProfileLevelId? {
    guard let str = str, str.count == 6, let numeric = Int(str, radix: 16), numeric != 0 else {
        return nil
    }

    let constraintSet3Flag = 0x10
    let levelIdc = H264Level(rawValue: numeric & 0xFF) ?? .L3_1
    let profileIop = (numeric >> 8) & 0xFF
    let profileIdc = (numeric >> 16) & 0xFF

    let level: H264Level
    if levelIdc == .L1_1 {
        level = (profileIop & constraintSet3Flag != 0) ? .L1_b : .L1_1
    } else {
        level = levelIdc
    }

    for pattern in profilePatterns {
        if profileIdc == pattern.profileIdc && pattern.profileIop.isMatch(profileIop) {
            return H264ProfileLevelId(profile: pattern.profile, level: level)
        }
    }
    return nil
}

func profileLevelIdToString(_ profileLevelId: H264ProfileLevelId) -> String {
    let profileIdcIop: String
    switch profileLevelId.profile {
    case .constrainedBaseline: profileIdcIop = "42e0"
    case .baseline: profileIdcIop = "4200"
    case .main: profileIdcIop = "4d00"
    case .constrainedHigh: profileIdcIop = "640c"
    case .high: profileIdcIop = "6400"
    case .predictiveHigh444: profileIdcIop = "f400"
    }

    let levelStr = String(format: "%02x", profileLevelId.level.rawValue)
    return profileIdcIop + levelStr
}

func isSameProfile(_ localParams: [String: String], _ remoteParams: [String: String]) -> Bool {
    let local = parseProfileLevelId(localParams["profile-level-id"]) ?? defaultProfileLevelId
    let remote = parseProfileLevelId(remoteParams["profile-level-id"]) ?? defaultProfileLevelId
    return local.profile == remote.profile
}

func generateProfileLevelIdStringForAnswer(localParams: [String: String], remoteParams: [String: String]) throws -> String {
    guard localParams["profile-level-id"] != nil || remoteParams["profile-level-id"] != nil else {
        throw NSError(domain: "H264", code: 1, userInfo: [NSLocalizedDescriptionKey: "No profile-level-id"])
    }

    let local = parseProfileLevelId(localParams["profile-level-id"]) ?? defaultProfileLevelId
    let remote = parseProfileLevelId(remoteParams["profile-level-id"]) ?? defaultProfileLevelId

    if local.profile != remote.profile {
        throw NSError(domain: "H264", code: 2, userInfo: [NSLocalizedDescriptionKey: "H264 Profile mismatch"])
    }

    let levelAsymmetryAllowed = (localParams["level-asymmetry-allowed"] == "1" || localParams["level-asymmetry-allowed"] == "true") &&
                                (remoteParams["level-asymmetry-allowed"] == "1" || remoteParams["level-asymmetry-allowed"] == "true")

    let answerLevel: H264Level = levelAsymmetryAllowed ? local.level : min(local.level, remote.level)
    return profileLevelIdToString(H264ProfileLevelId(profile: local.profile, level: answerLevel))
}
