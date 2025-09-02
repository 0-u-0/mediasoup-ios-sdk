//
//  Parser.swift
//  sdk
//
//  Created by cong chen on 2025/9/1.
//

import Foundation

class Parser{
    
    static func toType(_ value: String, type: Character) -> Any {
        switch type {
        case "d": // digit/integer
            return Int(value) ?? 0
        case "f": // float
            return Double(value) ?? 0.0
        case "s": // string
            fallthrough
        default:
            return value
        }
    }
    
    static func attachProperties(
        match: NSTextCheckingResult,
        source: String,
        keyLocation: inout [String: Any],
        names: [String],
        ruleName: String,
        types: [Character]
    ) {
        func substring(from result: NSTextCheckingResult, at idx: Int) -> String? {
            guard idx < result.numberOfRanges else { return nil }
            let range = result.range(at: idx)
            guard range.location != NSNotFound,
                  let swiftRange = Range(range, in: source) else {
                return nil
            }
            return String(source[swiftRange])
        }
        
        if !ruleName.isEmpty && names.isEmpty {
            if let val = substring(from: match, at: 1) {
                keyLocation[ruleName] = toType(val, type: types.first ?? "s")
            }
        } else {
            for i in 0..<names.count {
                if let val = substring(from: match, at: i + 1), !val.isEmpty {
                    keyLocation[names[i]] = toType(val, type: types[i])
                }
            }
        }
    }
    
    static func parseReg(rule: Grammar, location: inout [String: Any], content: String) {
        let needsBlank = !rule.name.isEmpty && !rule.names.isEmpty

        // 确保容器存在
        if !rule.push.isEmpty, location[rule.push] == nil {
            location[rule.push] = [[String: Any]]()
        } else if needsBlank, location[rule.name] == nil {
            location[rule.name] = [String: Any]()
        }

        // 正则匹配
        let fullRange = NSRange(content.startIndex..<content.endIndex, in: content)
        guard let match = rule.reg.firstMatch(in: content, options: [], range: fullRange) else { return }

        // 选择“工作副本”
        var keyLocation: [String: Any]
        if !rule.push.isEmpty {
            keyLocation = [:] // push: 新对象
        } else if needsBlank {
            keyLocation = (location[rule.name] as? [String: Any]) ?? [:]
        } else {
            keyLocation = location // 根对象的副本（值语义）
        }

        // 将匹配结果写入
        attachProperties(
            match: match,
            source: content,
            keyLocation: &keyLocation,
            names: rule.names,
            ruleName: rule.name,
            types: rule.types
        )

        // 把工作副本写回真正位置
        if !rule.push.isEmpty {
            var arr = (location[rule.push] as? [[String: Any]]) ?? []
            arr.append(keyLocation)
            location[rule.push] = arr
        } else if needsBlank {
            location[rule.name] = keyLocation
        } else {
            location = keyLocation
        }
    }
    
    static func parse(_ sdp: String) -> [String: Any] {
        let validLineRegex = try! NSRegularExpression(pattern: #"^([a-z])=(.*)"#)

        var session: [String: Any] = [:]
        var media: [[String: Any]] = []

        let lines = sdp.split(separator: "\n", omittingEmptySubsequences: false)
        for var line in lines {
            // 去掉结尾 \r
            if line.last == "\r" {
                line = line.dropLast()
            }

            let lineStr = String(line)

            // 校验合法
            let range = NSRange(location: 0, length: lineStr.utf16.count)
            if validLineRegex.firstMatch(in: lineStr, options: [], range: range) == nil {
                continue
            }

            let type = lineStr.first!
            let content = String(lineStr.dropFirst(2))

            if type == "m" {
                var m: [String: Any] = [:]
                m["rtp"] = [[String: Any]]()
                m["fmtp"] = [[String: Any]]()
                media.append(m)
            }

            guard let rules = Grammar.rulesMap[type] else {
                continue
            }

            for rule in rules {
                    let r = NSRange(location: 0, length: content.utf16.count)
                    if rule.reg.firstMatch(in: content, options: [], range: r) != nil {
                        if type == "m" || !media.isEmpty {
                            // 操作最后一个 media
                            var last = media.removeLast()
                            parseReg(rule: rule, location: &last, content: content)
                            media.append(last)
                        } else {
                            // 操作 session
                            parseReg(rule: rule, location: &session, content: content)
                        }
                        break
                    }
            
            }
        }

        session["media"] = media
        return session
    }
}
