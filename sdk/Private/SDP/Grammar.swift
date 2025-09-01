//
//  Grammar.swift
//  sdk
//
//  Created by cong chen on 2025/9/1.
//

import Foundation


class Grammar{
    var name: String
    var push: String
    var reg: NSRegularExpression?
    var names: [String]
    var types: [Character]
    var format: String
    var formatFunc: ((Any) -> String)?
    
    static let rulesMap: [Character: [Grammar]] = [
        "v": [
            Grammar(
                name: "version",
                push: "",
                reg: try! NSRegularExpression(pattern: #"^(\d*)$"#),
                names: [],
                types: ["d"],
                format: "%d"
            )
        ]
    ]

    
    init(name: String = "",
         push: String = "",
         reg: NSRegularExpression? = nil,
         names: [String] = [],
         types: [Character] = [],
         format: String = "",
         formatFunc: ((Any) -> String)? = nil) {
        self.name = name
        self.push = push
        self.reg = reg
        self.names = names
        self.types = types
        self.format = format
        self.formatFunc = formatFunc
    }
}
