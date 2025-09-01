//
//  ProtooClient.swift
//  sdk
//
//  Created by cong chen on 2025/8/18.
//

import Foundation
internal import Starscream

// MARK: - Protoo Message Types

enum ProtooMessageType: String {
    case request
    case response
    case notification
}

struct ProtooRequest: Codable {
    let request: Bool
    let id: Int
    let method: String
    let data: [String: AnyCodable]
}

struct ProtooResponse: Codable {
    let response: Bool
    let id: Int
    let ok: Bool
    let data: [String: AnyCodable]?
    let errorCode: Int?
    let errorReason: String?
}

struct ProtooNotification: Codable {
    let notification: Bool
    let method: String
    let data: [String: AnyCodable]
}

// Helper for Codable with Any
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let dictVal as [String: AnyCodable]:
            try container.encode(dictVal)
        case let arrayVal as [AnyCodable]:
            try container.encode(arrayVal)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unknown type"))
        }
    }
}

// MARK: - ProtooTransport

class ProtooTransport: WebSocketDelegate {

    
    private var socket: WebSocket
    private var isConnected = false
    var onOpen: (() -> Void)?
    var onClose: (() -> Void)?
    var onFailed: ((Int) -> Void)?
    var onDisconnected: (() -> Void)?
    var onMessage: ((String) -> Void)?

    private var retryCount = 0
    private let maxRetries = 10

    init(url: URL) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.setValue("protoo", forHTTPHeaderField: "Sec-WebSocket-Protocol")

        self.socket = WebSocket(request: request)
        self.socket.delegate = self
    }

    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }

    func send(_ text: String) {
        socket.write(string: text)
    }

    // MARK: - WebSocketDelegate

    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(_):
            isConnected = true
            retryCount = 0
            onOpen?()
        case .disconnected(let reason, let code):
            isConnected = false
            onDisconnected?()
            if retryCount < maxRetries {
                retryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + pow(2.0, Double(retryCount))) {
                    self.connect()
                }
            } else {
                onClose?()
            }
        case .text(let string):
            onMessage?(string)
        case .error(let error):
            onFailed?(retryCount)
            print("WebSocket error: \(String(describing: error))")
        default:
            break
        }
    }
}

// MARK: - ProtooPeer

class ProtooPeer {
    private let transport: ProtooTransport
    private var nextId: Int = 1
    private var pendingRequests: [Int: (Result<[String: AnyCodable], Error>) -> Void] = [:]

    var data: [String: Any] = [:]
    var connected: Bool = false
    var closed: Bool = false

    // Event handlers
    var onRequest: ((ProtooRequest, @escaping ([String: AnyCodable]) -> Void, @escaping (Int, String?) -> Void) -> Void)?
    var onNotification: ((ProtooNotification) -> Void)?
    var onOpen: (() -> Void)?
    var onClose: (() -> Void)?
    var onFailed: ((Int) -> Void)?
    var onDisconnected: (() -> Void)?

    init(transport: ProtooTransport) {
        self.transport = transport

        transport.onOpen = { [weak self] in
            self?.connected = true
            self?.onOpen?()
        }
        transport.onClose = { [weak self] in
            self?.closed = true
            self?.onClose?()
        }
        transport.onFailed = { [weak self] attempt in
            self?.onFailed?(attempt)
        }
        transport.onDisconnected = { [weak self] in
            self?.connected = false
            self?.onDisconnected?()
        }
        transport.onMessage = { [weak self] text in
            self?.handleMessage(text)
        }
    }

    func connect() {
        transport.connect()
    }

    func close() {
        transport.disconnect()
        closed = true
    }

    func request(method: String, data: [String: AnyCodable], completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        let id = nextId
        nextId += 1
        let request = ProtooRequest(request: true, id: id, method: method, data: data)
        pendingRequests[id] = completion
        if let jsonData = try? JSONEncoder().encode(request),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            transport.send(jsonString)
        }
    }

    func notify(method: String, data: [String: AnyCodable]) {
        let notification = ProtooNotification(notification: true, method: method, data: data)
        if let jsonData = try? JSONEncoder().encode(notification),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            transport.send(jsonString)
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        if let response = try? JSONDecoder().decode(ProtooResponse.self, from: data), response.response {
            if let completion = pendingRequests[response.id] {
                if response.ok, let responseData = response.data {
                    completion(.success(responseData))
                } else {
                    let error = NSError(domain: "Protoo", code: response.errorCode ?? -1, userInfo: [NSLocalizedDescriptionKey: response.errorReason ?? "Unknown error"])
                    completion(.failure(error))
                }
                pendingRequests.removeValue(forKey: response.id)
            }
        } else if let request = try? JSONDecoder().decode(ProtooRequest.self, from: data), request.request {
            let accept: ([String: AnyCodable]) -> Void = { responseData in
                let response = ProtooResponse(response: true, id: request.id, ok: true, data: responseData, errorCode: nil, errorReason: nil)
                if let jsonData = try? JSONEncoder().encode(response),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    self.transport.send(jsonString)
                }
            }
            let reject: (Int, String?) -> Void = { errorCode, errorReason in
                let response = ProtooResponse(response: true, id: request.id, ok: false, data: nil, errorCode: errorCode, errorReason: errorReason)
                if let jsonData = try? JSONEncoder().encode(response),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    self.transport.send(jsonString)
                }
            }
            onRequest?(request, accept, reject)
        } else if let notification = try? JSONDecoder().decode(ProtooNotification.self, from: data), notification.notification {
            onNotification?(notification)
        }
    }
}

extension ProtooPeer {
    func request(method: String, data: [String: AnyCodable]) async throws -> [String: AnyCodable] {
        return try await withCheckedThrowingContinuation { continuation in
            self.request(method: method, data: data) { result in
                switch result {
                case .success(let responseData):
                    continuation.resume(returning: responseData)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
