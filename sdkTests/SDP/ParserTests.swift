//
//  ParserTests.swift
//  sdk
//
//  Created by cong chen on 2025/9/2.
//

import XCTest
@testable import sdk

final class ParserTests: XCTestCase {

    let text = """
    v=0
    o=- 4097551137405824264 2 IN IP4 127.0.0.1
    s=-
    t=0 0
    a=group:BUNDLE 0 1
    a=extmap-allow-mixed
    a=msid-semantic: WMS
    m=audio 9 UDP/TLS/RTP/SAVPF 111 63 9 102 0 8 13 110 126
    c=IN IP4 0.0.0.0
    a=rtcp:9 IN IP4 0.0.0.0
    a=ice-ufrag:NNAX
    a=ice-pwd:vgbea/8i5IRRp6JfEhWl/nEH
    a=ice-options:trickle renomination
    a=fingerprint:sha-256 9A:22:54:46:4D:73:E7:28:57:BE:61:52:D1:D0:DE:4D:80:A4:F4:99:15:4F:9C:A7:57:6F:01:B5:5A:4C:91:C0
    a=setup:actpass
    a=mid:0
    a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level
    a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
    a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
    a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
    a=sendrecv
    a=msid:- 1dff25fe-2f6d-4f78-a300-830d3fccb841
    a=rtcp-mux
    a=rtcp-rsize
    a=rtpmap:111 opus/48000/2
    a=rtcp-fb:111 transport-cc
    a=fmtp:111 minptime=10;useinbandfec=1
    a=rtpmap:63 red/48000/2
    a=fmtp:63 111/111
    a=rtpmap:9 G722/8000
    a=rtpmap:102 ILBC/8000
    a=rtpmap:0 PCMU/8000
    a=rtpmap:8 PCMA/8000
    a=rtpmap:13 CN/8000
    a=rtpmap:110 telephone-event/48000
    a=rtpmap:126 telephone-event/8000
    a=ssrc:931888593 cname:CQU+W9bQppVgBCXd
    a=ssrc:931888593 msid:- 1dff25fe-2f6d-4f78-a300-830d3fccb841
    m=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 35 36 127 103 104
    c=IN IP4 0.0.0.0
    a=rtcp:9 IN IP4 0.0.0.0
    a=ice-ufrag:NNAX
    a=ice-pwd:vgbea/8i5IRRp6JfEhWl/nEH
    a=ice-options:trickle renomination
    a=fingerprint:sha-256 9A:22:54:46:4D:73:E7:28:57:BE:61:52:D1:D0:DE:4D:80:A4:F4:99:15:4F:9C:A7:57:6F:01:B5:5A:4C:91:C0
    a=setup:actpass
    a=mid:1
    a=extmap:14 urn:ietf:params:rtp-hdrext:toffset
    a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
    a=extmap:13 urn:3gpp:video-orientation
    a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
    a=extmap:5 http://www.webrtc.org/experiments/rtp-hdrext/playout-delay
    a=extmap:6 http://www.webrtc.org/experiments/rtp-hdrext/video-content-type
    a=extmap:7 http://www.webrtc.org/experiments/rtp-hdrext/video-timing
    a=extmap:8 http://www.webrtc.org/experiments/rtp-hdrext/color-space
    a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
    a=extmap:10 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id
    a=extmap:11 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id
    a=sendrecv
    a=msid:- e4435e4b-cd40-479f-aadd-df59df2be870
    a=rtcp-mux
    a=rtcp-rsize
    a=rtpmap:96 H264/90000
    a=rtcp-fb:96 goog-remb
    a=rtcp-fb:96 transport-cc
    a=rtcp-fb:96 ccm fir
    a=rtcp-fb:96 nack
    a=rtcp-fb:96 nack pli
    a=fmtp:96 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640c1f
    a=rtpmap:97 rtx/90000
    a=fmtp:97 apt=96
    a=rtpmap:98 H264/90000
    a=rtcp-fb:98 goog-remb
    a=rtcp-fb:98 transport-cc
    a=rtcp-fb:98 ccm fir
    a=rtcp-fb:98 nack
    a=rtcp-fb:98 nack pli
    a=fmtp:98 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f
    a=rtpmap:99 rtx/90000
    a=fmtp:99 apt=98
    a=rtpmap:100 VP8/90000
    a=rtcp-fb:100 goog-remb
    a=rtcp-fb:100 transport-cc
    a=rtcp-fb:100 ccm fir
    a=rtcp-fb:100 nack
    a=rtcp-fb:100 nack pli
    a=rtpmap:101 rtx/90000
    a=fmtp:101 apt=100
    a=rtpmap:35 AV1/90000
    a=rtcp-fb:35 goog-remb
    a=rtcp-fb:35 transport-cc
    a=rtcp-fb:35 ccm fir
    a=rtcp-fb:35 nack
    a=rtcp-fb:35 nack pli
    a=rtpmap:36 rtx/90000
    a=fmtp:36 apt=35
    a=rtpmap:127 red/90000
    a=rtpmap:103 rtx/90000
    a=fmtp:103 apt=127
    a=rtpmap:104 ulpfec/90000
    a=ssrc-group:FID 1779838353 1564090782
    a=ssrc:1779838353 cname:CQU+W9bQppVgBCXd
    a=ssrc:1779838353 msid:- e4435e4b-cd40-479f-aadd-df59df2be870
    a=ssrc:1564090782 cname:CQU+W9bQppVgBCXd
    a=ssrc:1564090782 msid:- e4435e4b-cd40-479f-aadd-df59df2be870
    """
    
    func testAdd() {
        let session = Parser.parse(text)
        let sdp = Writer.write(session: session)
        
        print(session.toJSONString(prettyPrinted: true)!)
        print(sdp)
//        let result = calc.add(2, 3)
//        XCTAssertEqual(result, 5, "2 + 3 应该等于 5")
        
    }
//
//    func testDivideByZeroThrows() {
//        XCTAssertThrowsError(try calc.divide(10, 0)) { error in
//            XCTAssertEqual(error as? Calculator.DivisionError, .divideByZero)
//        }
//    }
}
