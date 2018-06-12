//
//  Shared.swift
//  UnidirectionalDebugger
//
//  Created by Chris Eidhof on 31.05.18.
//  Copyright © 2018 objc.io. All rights reserved.
//

import Foundation

enum WriteError: Error, Equatable {
    case eof
    case other(Int)
}

extension OutputStream {
    func write(_ data: Data) throws -> Int {
        assert(!data.isEmpty, "Empty data will be interpreted as EOF")
        let result = data.withUnsafeBytes {
            self.write($0, maxLength: data.count)
        }
        if result == 0 { throw WriteError.eof }
        if result < 0 { throw WriteError.other(result) }
        return result
    }
}

class Writer: NSObject, StreamDelegate {
    let chunkSize = 1024
    let outputStream: OutputStream
    var remainder = Data()
    let onEnd: (Error?) -> ()
    init(_ outputStream: OutputStream, onEnd: @escaping (Error?) -> ()) {
        self.outputStream = outputStream
        self.onEnd = onEnd
        super.init()
        outputStream.delegate = self
    }
    
    func resume() {
        if remainder.isEmpty { return }
        while outputStream.streamStatus == .open && outputStream.hasSpaceAvailable && !remainder.isEmpty {
            let chunk = remainder.prefix(chunkSize)
            do {
                let bytesWritten = try outputStream.write(chunk)
                remainder.removeFirst(bytesWritten)
            } catch {
                if let e = error as? WriteError, e == .eof, remainder.isEmpty { continue }
                dump(error)
                print("Couldn't write")
            }
        }
    }
    
    func write(_ data: Data) {
        remainder.append(data)
        resume()
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            resume()
        case .errorOccurred:
            onEnd(aStream.streamError)
        case.endEncountered:
            onEnd(nil)
        case .hasSpaceAvailable:
            resume()
        default:
            print("other event: \(eventCode)")
            ()
        }
    }
}

// https://github.com/turn/json-over-tcp#protocol
struct JSONOverTCPDecoder {
    var payloadLength: Int?
    var buffer = Data()
    typealias Message = Data?
    let callback: (Message) -> ()
    init(_ callback: @escaping (Message) -> ()) {
        self.callback = callback
    }
    
    mutating func receive(_ data: Data) {
        buffer.append(data)
        var canContinue: Bool {
            if buffer.isEmpty { return false }
            if buffer.count > 5 && payloadLength == nil { return true }
            if let c = payloadLength, buffer.count >= c { return true }
            return false
        }
        while canContinue {
            if payloadLength == nil {
                guard buffer.removeFirst() == 206 else {
                    // Protocol signature error
                    callback(nil)
                    return
                }
                assert(buffer.count >= 4) // todo
                let lengthBytes = buffer.prefix(4)
                buffer.removeFirst(4)
                let length: Int32 = lengthBytes.withUnsafeBytes { $0.pointee }
                payloadLength = Int(length)
            }
            if let c = payloadLength, buffer.count >= c {
                let data = buffer.prefix(c)
                buffer.removeFirst(c)
                callback(data)
                payloadLength = nil
            }
        }
    }
}

class Reader: NSObject, StreamDelegate {
    let chunkSize = 1024
    enum Message {
        case data(Data)
        case streamDidEnd(success: Bool)
    }
    let onMessage: (Message) -> ()
    
    init(onMessage: @escaping (Message) -> ()) {
        self.onMessage = onMessage
        super.init()
    }
    
    func stream(_ stream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            ()
        case .errorOccurred:
            onMessage(.streamDidEnd(success: false))
        case.endEncountered:
            onMessage(.streamDidEnd(success: false))
        case .hasBytesAvailable:
            readBytes(stream as! InputStream)
        default:
            print("Uknown event: \(eventCode)")
            ()
        }
    }
    
    func readBytes(_ stream: InputStream) {
        while stream.hasBytesAvailable {
            var d = Data(count: chunkSize)
            let count = d.withUnsafeMutableBytes { body in
                stream.read(body, maxLength: chunkSize)
            }
            guard count != 0 else { print("eof"); return }
            if count < 0 { fatalError() }
            onMessage(.data(d[0..<count]))
        }
    }
}
