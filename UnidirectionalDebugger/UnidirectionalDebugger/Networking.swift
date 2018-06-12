//
//  Networking.swift
//  UnidirectionalDebugger
//
//  Created by Chris Eidhof on 24.05.18.
//  Copyright © 2018 objc.io. All rights reserved.
//

import Foundation

extension OutputStream {
    func setDispatchQueue(_ queue: DispatchQueue) {
        CFWriteStreamSetDispatchQueue(self, queue)
    }
}

extension InputStream {
    func setDispatchQueue(_ queue: DispatchQueue) {
        CFReadStreamSetDispatchQueue(self, queue)
    }
}

// todo I think the connection could store an A to associate state?
// todo use the Register struct to store the connections?
class ConnectionManager: NSObject, NetServiceDelegate {
    typealias Processor = (Data) -> ()
    
    struct Connection {
        let id: UUID
        let inputStream: InputStream
        let outputStream: OutputStream
        let delegate: Reader
        let writer: Writer
        let processor: Processor
    }

    var connections: [Connection] = []
    let queue = DispatchQueue(label: "DebugService")
    let createProcessor: () -> Processor
    init(_ createProcessor: @escaping () -> Processor) {
        self.createProcessor = createProcessor
    }
    
    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        inputStream.setDispatchQueue(queue)
        outputStream.setDispatchQueue(queue)
        let id = UUID()
        let processor = createProcessor()
        let reader = Reader { [unowned self] message in
            switch message {
            case .data(let data):
                processor(data) // this creates a strong reference (on purpose)
            case .streamDidEnd(_):
                self.closeConnection(id: id)
            }
        }
        let writer = Writer(outputStream) { [unowned self] err in
            self.closeConnection(id: id)
        }        
        inputStream.delegate = reader
        inputStream.open()
        outputStream.open()
        connections.append(Connection(id: id, inputStream: inputStream, outputStream: outputStream, delegate: reader, writer: writer, processor: processor))
    }
    
    func closeConnection(id: UUID) {
        guard let i = connections.index(where: { $0.id == id }) else { fatalError("Unknown connection with id: \(id)") }
        let conn = connections.remove(at: i)
        conn.inputStream.close()
        conn.outputStream.close()
    }
    
    func write(_ data: Data) {
        queue.async {
            for c in self.connections {
                c.writer.write(data)
            }
        }
    }
}

extension Int32 {
    var bytes: Data {
        var result = Data(count: 4)
        result.withUnsafeMutableBytes { $0.pointee = Int32(self) }
        return result
    }
}

class DebugServer: NSObject {
    let service: NetService
    var driver: ConnectionManager!
    
    init(onJSON: @escaping (Any) -> ()) {
        service = NetService(domain: "local.", type: "_debug._tcp", name: "", port: 0)
        super.init()
        driver = ConnectionManager {
            var receiver = JSONOverTCPDecoder { result in
                guard let d = result else { print("No data"); return }
                let obj = try! JSONSerialization.jsonObject(with: d, options: [])
                onJSON(obj)
            }
            return { receiver.receive($0) }
        }
        service.delegate = driver
        service.publish(options: .listenForConnections)
    }
    
    // Write using the TCP over JSON protocol:
    // - first a 206 byte
    // - then an UInt32 with the length (encoded as 4 bytes)
    // - then the JSON data
    func write(json: Any) {
        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        driver.write([206] + Int32(data.count).bytes + data)
    }
}
