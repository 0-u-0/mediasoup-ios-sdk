//
//  Grammar.swift
//  sdk
//
//  Created by cong chen on 2025/9/1.
//

import Foundation


class Grammar{
    let name: String
    let push: String
    let reg: NSRegularExpression
    let names: [String]
    let types: [Character]
    let format: String
    let formatFunc: (([String: Any]) -> String)?

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
        ],
        "o": [
            Grammar(
                name: "origin",
                push: "",
                reg: try! NSRegularExpression(pattern: #"^(\S*) (\d*) (\d*) (\S*) IP(\d) (\S*)"#),
                names: ["username", "sessionId", "sessionVersion", "netType", "ipVer", "address"],
                types: ["s", "u", "u", "s", "d", "s"],
                format: "%s %d %d %s IP%d %s"
            )
        ],
        "s": [
            Grammar(
                name: "name",
                push: "",
                reg: try! NSRegularExpression(pattern: #"(.*)"#),
                names: [],
                types: ["s"],
                format: "%s"
            )
        ],
        "i": [
            Grammar(
                name: "description",
                push: "",
                reg: try! NSRegularExpression(pattern: #"(.*)"#),
                names: [],
                types: ["s"],
                format: "%s"
            )
        ],
        "u": [
            Grammar(
                name: "uri",
                push: "",
                reg: try! NSRegularExpression(pattern: #"(.*)"#),
                names: [],
                types: ["s"],
                format: "%s"
            )
        ],
        "e": [
            Grammar(
                name: "email",
                push: "",
                reg: try! NSRegularExpression(pattern: #"(.*)"#),
                names: [],
                types: ["s"],
                format: "%s"
            )
        ],
        "p": [
            Grammar(
                name: "phone",
                push: "",
                reg: try! NSRegularExpression(pattern: #"(.*)"#),
                names: [],
                types: ["s"],
                format: "%s"
            )
        ],
        "z": [
            Grammar(
                name: "timezones",
                push: "",
                reg: try! NSRegularExpression(pattern: #"(.*)"#),
                names: [],
                types: ["s"],
                format: "%s"
            )
        ],
        "r": [
            Grammar(
                name: "repeats",
                push: "",
                reg: try! NSRegularExpression(pattern: #"(.*)"#),
                names: [],
                types: ["s"],
                format: "%s"
            )
        ],
        "t": [
            Grammar(
                name: "timing",
                push: "",
                reg: try! NSRegularExpression(pattern: #"^(\d*) (\d*)"#),
                names: ["start", "stop"],
                types: ["d", "d"],
                format: "%d %d"
            )
        ],
        "c": [
            Grammar(
                name: "connection",
                push: "",
                reg: try! NSRegularExpression(pattern: #"^IN IP(\d) ([^\s/]*)(?:/(\d*))?"#),
                names: ["version", "ip", "ttl"],
                types: ["d", "s", "d"],
                format: "",
                formatFunc: { o in
                    if o["ttl"] != nil {
                        return "IN IP%d %s/%d"
                    } else {
                        return "IN IP%d %s"
                    }
                }
            )
        ],
        "b": [
            Grammar(
                name: "",
                push: "bandwidth",
                reg: try! NSRegularExpression(pattern: #"^(TIAS|AS|CT|RR|RS):(\d*)"#),
                names: ["type", "limit"],
                types: ["s", "d"],
                format: "%s:%d"
            )
        ],
        "m": [
            Grammar(
                name: "media",
                push: "media",
                reg: try! NSRegularExpression(pattern: #"^(\w*) (\d*) ([\w/]*)(?: (.*))?"#),
                names: ["type", "port", "protocol", "payloads"],
                types: ["s", "u", "s", "s"],
                format: "%s %d %s %s"
            )
        ],
        "a": [
            Grammar(
                name: "",
                push: "rtp",
                reg: try! NSRegularExpression(pattern: #"^rtpmap:(\d*) ([^/]*)(?:/(\d*)(?:/(\S*))?)?"#),
                names: ["payload", "codec", "rate", "encoding"],
                types: ["d", "s", "d", "s"],
                format: "rtpmap:%d %s/%d/%s",
                formatFunc: { o in
                    if o["encoding"] != nil {
                        return "rtpmap:%d %s/%d/%s"
                    } else if o["rate"] != nil {
                        return "rtpmap:%d %s/%d"
                    } else {
                        return "rtpmap:%d %s"
                    }
                }
            ),
            Grammar(
                name: "fmtp",
                push: "fmtp",
                reg: try! NSRegularExpression(pattern: #"^fmtp:(\d*) ([\S| ]*)"#),
                names: ["payload", "config"],
                types: ["d", "s"],
                format: "fmtp:%d %s"
            ),
            Grammar(
                name: "control",
                push: "",
                reg: try! NSRegularExpression(pattern: #"^control:(.*)"#),
                names: ["control"],
                types: ["s"],
                format: "control:%s"
            ),
            Grammar(
                name: "rtcp",
                push: "",
                reg: try! NSRegularExpression(pattern: #"^rtcp:(\d*)(?: (\S*) IP(\d) (\S*))?"#),
                names: ["port", "netType", "ipVer", "address"],
                types: ["d", "s", "d", "s"],
                format: "",
                formatFunc: { o in
                    if o["address"] != nil {
                        return "rtcp:%d %s IP%d %s"
                    } else {
                        return "rtcp:%d"
                    }
                }
            ),
            Grammar(
                name: "candidate",
                push: "candidates",
                reg: try! NSRegularExpression(pattern: #"^candidate:(\S*) (\d*) (\S*) (\d*) (\S*) (\d*) typ (\S*)(?: raddr (\S*) rport (\d*))?(?: generation (\d*))?"#),
                names: ["foundation", "component", "transport", "priority", "ip", "port", "type", "raddr", "rport", "generation"],
                types: ["s","u","s","u","s","u","s","s","u","u"],
                format: "candidate:%s %d %s %d %s %d typ %s raddr %s rport %d generation %d",
                formatFunc: { o in
                    var str = "candidate:%s %d %s %d %s %d typ %s"
                    if o["raddr"] != nil {
                        str += " raddr %s rport %d"
                    }
                    if o["generation"] != nil {
                        str += " generation %d"
                    }
                    return str
                }
            ),
            Grammar(
                name: "ssrc",
                push: "ssrcs",
                reg: try! NSRegularExpression(pattern: #"^ssrc:(\d*) ([^:]*)(?::(.*))?"#),
                names: ["id", "attribute", "value"],
                types: ["u","s","s"],
                format: "ssrc:%u %s:%s",
                formatFunc: { o in
                    if o["value"] != nil {
                        return "ssrc:%u %s:%s"
                    } else {
                        return "ssrc:%u %s"
                    }
                }
            ),
            Grammar(
                name: "ssrcGroup",
                push: "ssrcGroups",
                reg: try! NSRegularExpression(pattern: #"^ssrc-group:(\S*) (.*)"#),
                names: ["semantics", "ssrcs"],
                types: ["s","s"],
                format: "ssrc-group:%s %s"
            ),
            Grammar(
                name: "mid",
                push: "",
                reg: try! NSRegularExpression(pattern: #"^mid:(\S*)"#),
                names: ["mid"],
                types: ["s"],
                format: "mid:%s"
            ),
            Grammar(
                name: "msid",
                push: "",
                reg: try! NSRegularExpression(pattern: #"^msid:(\S*) (\S*)"#),
                names: ["msid", "appdata"],
                types: ["s","s"],
                format: "msid:%s %s"
            )
        ]
    ]

    
    init(
        name: String,
        push: String,
        reg: NSRegularExpression,
        names: [String],
        types: [Character],
        format: String,
        formatFunc: (([String: Any]) -> String)? = nil
    ) {
        self.name = name
        self.push = push
        self.reg = reg
        self.names = names
        self.types = types
        self.format = format
        self.formatFunc = formatFunc
    }
}
