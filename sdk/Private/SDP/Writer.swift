//
//  Writer.swift
//  sdk
//
//  Created by cong chen on 2025/9/1.
//

import Foundation

class Writer{
    
    static func makeLine(
        sdp: inout String,
        type: Character,
        rule: Grammar,
        location: [String: Any]
    ) {
        let format: String
        if rule.format.isEmpty {
            // 调用 formatFunc
            if let funcBlock = rule.formatFunc {
                if !rule.push.isEmpty {
                    format = funcBlock(location)
                } else if !rule.name.isEmpty,
                    let sub = location[rule.name] {
                        format = funcBlock(sub as! [String : Any])
                    } else {
                        format = funcBlock(location)
                    }
            } else {
                format = ""
            }
        } else {
            format = rule.format
        }

        // 收集参数
        var args: [Any] = []
        if !rule.names.isEmpty {
            for name in rule.names {
                if !rule.name.isEmpty,
                   let dict = location[rule.name] as? [String: Any],
                   let val = dict[name] {
                    args.append(val)
                } else if let val = location[name] {
                    args.append(val)
                } else {
                    args.append("") // 空值
                }
            }
        } else if let val = location[rule.name] {
            args.append(val)
        }

        // 构造行
        var line = "\(type)="
        let regex = try! NSRegularExpression(pattern: "%[sdv%]")
        let nsFormat = format as NSString
        var lastIndex = 0
        var argIndex = 0

        let matches = regex.matches(in: format, range: NSRange(location: 0, length: nsFormat.length))
        for match in matches {
            let matchRange = match.range
            let prefixRange = NSRange(location: lastIndex, length: matchRange.location - lastIndex)
            line += nsFormat.substring(with: prefixRange)

            let token = nsFormat.substring(with: matchRange)

            if argIndex >= args.count {
                line += token
            } else {
                let arg = args[argIndex]
                argIndex += 1

                switch token {
                case "%%":
                    line += "%"
                case "%s", "%d":
                    if let str = arg as? String {
                        line += str
                    } else {
                        line += "\(arg)"
                    }
                case "%v":
                    // 跳过
                    break
                default:
                    line += token
                }
            }

            lastIndex = matchRange.location + matchRange.length
        }

        // 添加剩余部分
        if lastIndex < nsFormat.length {
            line += nsFormat.substring(from: lastIndex)
        }

        line += "\r\n"
        sdp += line
    }
    
    static func write(session inputSession: [String: Any]) -> String {
        let outerOrder: [Character] = ["v","o","s","i","u","e","p","c","b","t","r","z","a"]
        let innerOrder: [Character] = ["i","c","b","a"]

        var session = inputSession // copy，因为字典是值类型

        // 确保存在必要属性
        if session["version"] == nil { session["version"] = 0 }
        if session["name"] == nil { session["name"] = "-" }
        if session["media"] == nil { session["media"] = [[String: Any]]() }

        var mediaArray = session["media"] as? [[String: Any]] ?? []
        for i in 0..<mediaArray.count {
            if mediaArray[i]["payloads"] == nil {
                mediaArray[i]["payloads"] = ""
            }
        }
        session["media"] = mediaArray

        var sdp = ""

        // OuterOrder 遍历 session
        for type in outerOrder {
            guard let rules = Grammar.rulesMap[type] else { continue }
            for rule in rules {
                if !rule.name.isEmpty,
                   let val = session[rule.name] {
                    makeLine(sdp: &sdp, type: type, rule: rule, location: session)
                } else if !rule.push.isEmpty,
                          let arr = session[rule.push] as? [[String: Any]] {
                    for el in arr {
                        makeLine(sdp: &sdp, type: type, rule: rule, location: el)
                    }
                }
            }
        }

        // 对每个 media line，InnerOrder
        mediaArray = session["media"] as? [[String: Any]] ?? []
        for mLine in mediaArray {
            // 先 m line
            if let mRules = Grammar.rulesMap["m"], !mRules.isEmpty {
                makeLine(sdp: &sdp, type: "m", rule: mRules[0], location: mLine)
            }

            for type in innerOrder {
                guard let rules = Grammar.rulesMap[type] else { continue }
                for rule in rules {
                    if !rule.name.isEmpty,
                       let val = mLine[rule.name] {
                        makeLine(sdp: &sdp, type: type, rule: rule, location: mLine)
                    } else if !rule.push.isEmpty,
                              let arr = mLine[rule.push] as? [[String: Any]] {
                        for el in arr {
                            makeLine(sdp: &sdp, type: type, rule: rule, location: el)
                        }
                    }
                }
            }
        }

        return sdp
    }
}
