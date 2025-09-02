//
//  Dictionary+JSON.swift
//  sdk
//
//  Created by cong chen on 2025/9/2.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    func toJSONString(prettyPrinted: Bool = true) -> String? {
        guard JSONSerialization.isValidJSONObject(self) else {
            return nil
        }
        let options: JSONSerialization.WritingOptions = prettyPrinted ? .prettyPrinted : []
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: options)
            return String(data: data, encoding: .utf8)
        } catch {
            print("❌ JSON serialization error: \(error)")
            return nil
        }
    }
}
