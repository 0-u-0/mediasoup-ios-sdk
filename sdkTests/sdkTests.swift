//
//  sdkTests.swift
//  sdkTests
//
//  Created by cong chen on 2025/3/22.
//

import Testing
import Foundation

@testable import sdk

struct sdkTests {

    @Test func example() async throws {

        let text = "rtpmap:111 opus/48000/2"
        let pattern = #"^rtpmap:(\d*) ([^/]*)(?:/(\d*)(?:/(\S*))?)?"#

        if let regex = try? NSRegularExpression(pattern: pattern) {
            if let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                print("match \(match.numberOfRanges)")
                for i in 0..<match.numberOfRanges {
                    if let range = Range(match.range(at: i), in: text) {
                        print("Group \(i):", text[range])
                    }
                }
            }
        }
    }

}
