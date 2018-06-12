import Foundation

struct AppState: Codable, Equatable {
	enum CodingKeys: CodingKey {
		case folders
		case playState
	}
	
//	func encode(to encoder: Encoder) throws {
//		var c = encoder.container(keyedBy: Keys.self)
//		try c.encode(folders, forKey: .folders)
//	}
//
//	init(from decoder: Decoder) throws {
//		let c = try decoder.container(keyedBy: Keys.self)
//		if let f = try c.decodeIfPresent(Array<Folder>.self, forKey: .folders) {
//			folders = f
//		} else {
//			throw DecodingError.keyNotFound(Keys.folders, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Folders key must always be present"))
//		}
//		playState = nil
//		recordState = nil
//	}
	
	var folders: [Folder]
	var playState: PlayerState?
	var recordState: RecordState?
	
	init(rootFolder: Folder) {
		folders = [rootFolder]
		playState = nil
		recordState = nil
	}
	
	var currentFolder: Folder {
		get { return folders[folders.count - 1] }
		set { folders[folders.count - 1] = newValue }
	}
}

struct RecordState: Equatable {
	var recorder: Recorder
	let folder: Folder
	var duration: TimeInterval
	
	init(folder: Folder, recorder: Recorder) {
		self.recorder = recorder
		self.folder = folder
		duration = 0
	}
}

struct PlayerState: Equatable, Codable {
	enum CodingKeys: CodingKey {
		case recording
		case name
		case position
		case duration
	}
	var recording: Recording
	var name: String
	var position: TimeInterval
	var duration: TimeInterval
	var playing: Bool = false
	
	init(recording: Recording, duration: TimeInterval) {
		(self.recording, name, position, self.duration, playing) = (recording, recording.name, 0, duration, false)
	}
}
