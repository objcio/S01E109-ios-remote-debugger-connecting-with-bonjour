import Foundation

// << elm-cm-1
// << elm-cvs-1-1
// << elm-cvs-2-1
extension AppState {
	// >> elm-cvs-2-1
	// >> elm-cvs-1-1
	enum Message: Equatable {
		// >> elm-cm-1
		// Navigation
		case back
		case popDetail
		
		case player(PlayerState.Message)
		case recording(RecordState.Message)
		case createNewRecording
		case showCreateFolderPrompt
		case createFolder(String?)
		case selectFolder(Folder)
		case selectRecording(Recording)
		// << elm-cm-1
		case delete(Item)
		// >> elm-cm-1 ...
		case storeChanged(Folder)
		case recorderAvailable(Recorder?)
		case loaded(Recording, TimeInterval?)
		
		static func select(_ item: Item) -> Message {
			switch item {
			case let .folder(folder): return .selectFolder(folder)
			case let .recording(recording): return .selectRecording(recording)
			}
		}
		// << elm-cm-1
	}
	// >> elm-cm-1
	
	// << elm-cm-2-1
	// << elm-cm-4-1
	// << elm-cvs-1-1
	// << elm-cvs-2-1
	// << elm-fw-hc-1 AppState
	mutating func update(_ msg: Message) -> [Command<Message>] {
		switch msg {
		// >> elm-fw-hc-1
		// >> elm-cvs-2-1
		// >> elm-cm-4-1
		// >> elm-cm-2-1
		// >> elm-cvs-1-1
		case .popDetail:
			if playState != nil {
				playState = nil
			}
			return []
		case .back:
			folders.removeLast()
			return []
		case .createNewRecording:
			return [Command.createRecorder(available: { .recorderAvailable($0) })]
		case .recorderAvailable(let recorder):
			guard let recorder = recorder else {
				return [Command.modalAlert(title: "Cannot record", accept: "OK")]
			}
			self.recordState = RecordState(folder: currentFolder, recorder: recorder)
			return []
		// << elm-cvs-2-1
		case let .selectFolder(folder):
			folders.append(folder)
			return []
		// >> elm-cvs-2-1 ...
		case let .selectRecording(recording):
			return [Command.load(recording: recording, available: { .loaded(recording, $0) })]
		// << elm-cm-2-1
		// << elm-fw-hc-1
		case .delete(let item):
			return [Command.delete(item)]
		// >> elm-fw-hc-1 ...
		// >> elm-cm-2-1 ...
		case .recording(let recordingMsg):
			let result: [Command<RecordState.Message>]? = recordState?.update(recordingMsg)
			if case .save(_) = recordingMsg {
				recordState = nil
			}
			return result?.map { recordCommand in
				return recordCommand.map(Message.recording)
			} ?? []
		// << elm-cvs-1-1
		case .player(let msg):
			return playState?.update(msg) ?? []
		// >> elm-cvs-1-1 ...
		case .loaded(let r, let duration):
			guard let d = duration else {
				return [Command.modalAlert(title: "Cannot play \(r.name)", accept: "OK")]
			}
			playState = PlayerState(recording: r, duration: d)
			return []
		case .showCreateFolderPrompt:
			return [Command.modalTextAlert(title: .createFolder,
				accept: .create,
				cancel: .cancel,
				placeholder: .folderName,
				submit: { .createFolder($0) })]
		case .createFolder(let name):
			guard let s = name else { return [] }
			return [Command.createFolder(name: s, parent: currentFolder)]
		// << elm-cm-4-1 ...
		case .storeChanged(let root):
			folders = folders.compactMap { root.find($0) }
			// >> elm-cm-4-1 ...
			if let recording = playState?.recording {
				if let newRecording = root.find(recording) {
					playState?.recording = newRecording
				} else {
					playState = nil
				}
			}
			// << elm-cm-4-1
			return []
		// << elm-cm-2-1
		// << elm-cvs-1-1
		// << elm-cvs-2-1
		// << elm-fw-hc-1
		}
	}
	// >> elm-fw-hc-1
	// >> elm-cm-4-1
	// >> elm-cm-2-1
	// << elm-cm-1
}
// >> elm-cvs-2-1
// >> elm-cvs-1-1
// >> elm-cm-1

// << elm-cm-3-1
extension AppState {
	var subscriptions: [Subscription<Message>] {
		var subs: [Subscription<Message>] = [
			.storeChanged(handle: { .storeChanged($0) })
		]
		// >> elm-cm-3-1 ...
		if let r = recordState?.recorder {
			subs.append(.recordProgress(recorder: r, handle: { .recording(.progressChanged($0)) }))
		}
		if let p = playState {
			subs.append(.playProgress(handle: { Message.player(.playPositionChanged($0, isPlaying: $1)) }))
		}
		// << elm-cm-3-1
		return subs
	}
}
// >> elm-cm-3-1

fileprivate extension String {
	static let createFolder = NSLocalizedString("Create Folder", comment: "Header for folder creation dialog")
	static let create = NSLocalizedString("Create", comment: "Confirm button for folder creation dialog")
	static let folderName = NSLocalizedString("Folder Name", comment: "Placeholder for text field where folder name should be entered.")
}
