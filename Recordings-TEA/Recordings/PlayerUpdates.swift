import Foundation

// << elm-cvs-1-2
extension PlayerState {
	// >> elm-cvs-1-2
	enum Message: Equatable {
		case togglePlay
		case nameChanged(String?)
		case saveName(String?)
		case seek(Float)
		case playPositionChanged(TimeInterval?, isPlaying: Bool)
	}
	
	// << elm-cvs-1-2
	mutating func update(_ action: Message) -> [Command<AppState.Message>] {
		switch action {
		// >> elm-cvs-1-2
		case let .nameChanged(name):
			self.name = name ?? ""
			return []
		case let .saveName(name):
			return [Command.changeName(of: recording, to: name ?? "")]
		// << elm-cvs-1-2
		case .togglePlay:
			playing = !playing
			return [Command.togglePlay()]
		// >> elm-cvs-1-2 ...
		case let .playPositionChanged(position, isPlaying):
			self.position = position ?? duration
			playing = isPlaying
		case let .seek(progress):
			return [Command.seek(to: TimeInterval(progress))]
		// << elm-cvs-1-2
		}
		// >> elm-cvs-1-2
		return []
		// << elm-cvs-1-2
	}
}
// >> elm-cvs-1-2
