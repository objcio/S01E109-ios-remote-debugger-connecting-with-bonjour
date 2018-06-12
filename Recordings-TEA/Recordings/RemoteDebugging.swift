//
//  RemoteDebugging.swift
//  Recordings
//
//  Created by Chris Eidhof on 24.05.18.
//

import UIKit

extension UIView {
	func capture() -> UIImage? {
		let format = UIGraphicsImageRendererFormat()
		format.opaque = isOpaque
		let renderer = UIGraphicsImageRenderer(size: frame.size, format: format)
		return renderer.image { _ in
			drawHierarchy(in: frame, afterScreenUpdates: true)
		}
	}
}

struct DebugData<S: Encodable>: Encodable {
	var state: S
	var action: String
	var imageData: Data
}

final class RemoteDebugger: NSObject, NetServiceBrowserDelegate {
	let browser = NetServiceBrowser()
	let queue = DispatchQueue(label: "remoteDebugger")
	var output: OutputStream?
	
	override init() {
		super.init()
		browser.delegate = self
		browser.searchForServices(ofType: "_debug._tcp", inDomain: "local")
	}
	
	func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
		var input: InputStream?
		service.getInputStream(&input, outputStream: &output)
		CFReadStreamSetDispatchQueue(input, queue)
		CFWriteStreamSetDispatchQueue(output, queue)
		output?.open()
	}
	
	func write<S: Encodable>(action: String, state: S, snapshot: UIView) throws {
		guard let o = output else { return }
		
		let image = snapshot.capture()!
		let imageData = UIImagePNGRepresentation(image)!
		let data = DebugData(state: state, action: action, imageData: imageData)
		let encoder = JSONEncoder()
		let json = try! encoder.encode(data)
		var encodedLength = Data(count: 4)
		encodedLength.withUnsafeMutableBytes { bytes in
			bytes.pointee = Int32(json.count)
		}
		o.write(([206] + encodedLength) as [UInt8], maxLength: 5)
		let bytesWritten = json.withUnsafeBytes { bytes in
			o.write(bytes, maxLength: json.count)
		}
		assert(bytesWritten == json.count)
	}
}
