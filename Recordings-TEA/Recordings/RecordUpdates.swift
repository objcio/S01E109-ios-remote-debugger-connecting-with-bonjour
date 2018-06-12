import Foundation

// << elm-record-state-update
extension RecordState {
	// >> elm-record-state-update ...
	enum Message: Equatable {
		case stop
		case save(name: String?)
		case progressChanged(TimeInterval?)
	}
	
	// << elm-record-state-update
	mutating func update<C>(_ message: Message) -> [C]
		where C: CommandProtocol, C.Message == Message {
		switch message {
		// >> elm-record-state-update ...
		case .stop:
			return [
				C.stopRecorder(recorder),
				C.modalTextAlert(title: .saveRecording, accept: .save, cancel: .cancel, placeholder: .nameForRecording, submit: { .save(name: $0) })
			]
		// << elm-record-state-update
		case let .save(name: name):
			guard let name = name, !name.isEmpty else {
				// show that we can't save...
				return []
			}
			return [C.saveRecording(name: name, folder: folder, url: recorder.url)]
		// >> elm-record-state-update ...
		case let .progressChanged(value):
			if let v = value {
				self.duration = v
			}
			return []
		// << elm-record-state-update
		}
	}
}
// >> elm-record-state-update

// << elm-command-protocol
protocol CommandProtocol {
	associatedtype Message
	// >> elm-command-protocol ...
	static func stopRecorder(_ r: Recorder) -> Self
	static func modalTextAlert(title: String, accept: String, cancel: String, placeholder: String, submit: @escaping (String?) -> Message) -> Self
	// << elm-command-protocol
	static func saveRecording(name: String, folder: Folder, url: URL) -> Self
}
// >> elm-command-protocol

// << elm-command-protocol-conformance
extension Command: CommandProtocol { }
// >> elm-command-protocol-conformance

// << elm-explicit-command
enum CommandEnum<Message>: CommandProtocol {
	// >> elm-explicit-command ...
	case _stopRecorder(Recorder)
	case _modalTextAlert(title: String, accept: String, cancel: String, placeholder: String, submit: (String?) -> Message)
	// << elm-explicit-command
	case _saveRecording(name: String, folder: Folder, url: URL)
	// >> elm-explicit-command ...


	static func stopRecorder(_ r: Recorder) -> CommandEnum<Message> {
		return _stopRecorder(r)
	}

	static func modalTextAlert(title: String, accept: String, cancel: String, placeholder: String, submit: @escaping (String?) -> Message) -> CommandEnum<Message> {
		return ._modalTextAlert(title: title, accept: accept, cancel: cancel, placeholder: placeholder, submit: submit)
	}

	static func saveRecording(name: String, folder: Folder, url: URL) -> CommandEnum<Message> {
		return ._saveRecording(name: name, folder: folder, url: url)
	}
	// << elm-explicit-command
}
// >> elm-explicit-command


extension String {
	static let saveRecording = NSLocalizedString("Save recording", comment: "Heading for audio recording save dialog")
	static let save = NSLocalizedString("Save", comment: "Confirm button text for audio recoding save dialog")
	static let nameForRecording = NSLocalizedString("Name for recording", comment: "Placeholder for audio recording name text field")
}
