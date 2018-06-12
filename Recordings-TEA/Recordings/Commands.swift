import UIKit


// << elm-fw-hc-3
extension Command {
	// >> elm-fw-hc-3 ...
	static func load(recording: Recording, available: @escaping (TimeInterval?) -> Message) -> Command {
		return Command { context in
			let url = Store.shared.fileURL(for: recording)
			let player = Player(url: url)
			context.setPlayer(player)
			context.send(available(player?.duration))
		}
	}
	
	static func togglePlay() -> Command {
		return Command { ctx in
			ctx.player()?.togglePlay()
		}
	}
	
	static func seek(to position: TimeInterval) -> Command {
		return Command {
			$0.player()?.setProgress(position)
		}
	}
	
	static func saveRecording(name: String, folder: Folder, url: URL) -> Command {
		return Command { _ in
			let recording = Recording(name: name, uuid: UUID())
			let destination = Store.shared.fileURL(for: recording)
			try! FileManager.default.copyItem(at: url, to: destination)
			Store.shared.add(.recording(recording), to: folder)
		}
	}
	
	static func stopRecorder(_ recorder: Recorder) -> Command {
		return Command { _ in
			recorder.stop()
		}
	}
	
	// << elm-fw-hc-3
	static func delete(_ item: Item) -> Command {
		return Command { _ in
			Store.shared.delete(item)
		}
	}
	// >> elm-fw-hc-3
	
	static func createFolder(name: String, parent: Folder) -> Command {
		return Command { _ in
			let newFolder = Folder(name: name, uuid: UUID())
			Store.shared.add(.folder(newFolder), to: parent)
		}
	}
	
	static func createRecorder(available: @escaping (Recorder?) -> Message) -> Command {
		return Command { context in
			context.send(available(Recorder(url: Store.shared.tempURL())))
		}
	}
	
	static func changeName(of recording: Recording, to name: String) -> Command<Message> {
		return Command { _ in
			Store.shared.changeName(.recording(recording), to: name)
		}
	}
	// << elm-fw-hc-3
}
// >> elm-fw-hc-3
