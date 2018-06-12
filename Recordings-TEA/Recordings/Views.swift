import UIKit

// << elm-cv-1
// << elm-cv-2
// << elm-cm-5-1
extension AppState {
	// >> elm-cv-2
	// >> elm-cm-5-1
//	var viewController: ViewController<Message> {
//		let rootView = SplitViewController<Message>(
//			left: { _ in self.master },
//			right: self.detail,
//			collapseSecondaryViewController: playState == nil,
//			popDetail: .popDetail)
//		return .splitViewController(rootView, modal: recordModal)
//	}
	// >> elm-cv-1
	
	// << elm-cv-2
	// << elm-cm-5-1
	var viewController: ViewController<Message> {
		var viewControllers: [NavigationItem<Message>] = folders.map { folder in
			// << elm-cm-2
			let tv: TableView<Message> = folder.tableView(onSelect: Message.select, onDelete: Message.delete)
			// >> elm-cm-2
			// >> elm-cv-2 ...
			return NavigationItem(title: folder.name,
				// >> elm-cm-5-1 ...
				leftBarButtonItem: .editButtonItem,
				rightBarButtonItems: [.system(.add, action: .createNewRecording),
					.system(.organize, action: .showCreateFolderPrompt)],
				leftItemsSupplementsBackButton: true,
				// << elm-cm-5-1
				viewController: .tableViewController(tv))
			// << elm-cv-2
		}
		if let playerVC: ViewController<Message> = playState?.viewController.map({ .player($0) }) {
			let ni = NavigationItem(title: playState?.recording.name ?? "", leftBarButtonItem: .none, viewController: playerVC)
			viewControllers.append(ni)
		}
		return ViewController.navigationController(NavigationController(viewControllers: viewControllers, back: .back, popDetail: .popDetail), modal: recordModal)
	}
	// >> elm-cm-5-1
	// >> elm-cv-2
	
//	func detail(displayModeButton: UIBarButtonItem?) -> NavigationController<Message> {
//		let playerVC: ViewController<Message>? = playState?.viewController.map { .player($0) }
//		return NavigationController<Message>(viewControllers: [
//
//		])
//	}
	
	var recordModal: Modal<Message>? {
		return recordState.map { rec in
			Modal(viewController:
				recordViewController(duration: rec.duration, onStop: .recording(.stop)),
				presentationStyle: .formSheet)
		}
	}
	// << elm-cv-1
	// << elm-cv-2
}
// >> elm-cv-2
// >> elm-cv-1

// << elm-cv-3
// << elm-cm-5-2
extension Folder {
	func tableView<Message>(onSelect: (Item) -> Message, onDelete: (Item) -> Message) -> TableView<Message> {
		return TableView(items: items.map { item in
			let text: String
			switch item {
			case let .folder(folder):
				text = "📁  \(folder.name)"
			case let .recording(recording):
				text = "🔊  \(recording.name)"
			}
			return TableViewCell(identity: AnyHashable(item.uuid), text: text, onSelect: onSelect(item), onDelete: onDelete(item))
		})
	}
}
// >> elm-cm-5-2
// >> elm-cv-3

func noRecordingSelected<A>() -> ViewController<A> {
	return .viewController(.stackView(views: [.label(text: "No recording selected", font: .preferredFont(forTextStyle: .body))]))
}

// << elm-cvs-1-3
// << elm-cvs-1-4
extension PlayerState {
	// >> elm-cvs-1-3
	var view: View<Message> {
		// >> elm-cvs-1-4 ...
		let nameView: View<Message> = View<Message>.stackView(views: [
			.label(text: "Name", font: .preferredFont(forTextStyle: .body)),
			.space(width: 10),
			.textField(text: name, onChange: { .nameChanged($0) }, onEnd: { .saveName($0) })
		], axis: .horizontal, distribution: .fill)
		
		let progressLabels: View<Message> = .stackView(views: [
			.label(text: timeString(position), font: .preferredFont(forTextStyle: .body)),
			.label(text: timeString(duration), font: .preferredFont(forTextStyle: .body))
		], axis: .horizontal)
		// << elm-cvs-1-4
		// << elm-fw-dva-1
		return View<Message>.stackView(views: [
			.stackView(views: [
				// >> elm-fw-dva-1 ...
				// >> elm-cvs-1-4 ...
				.space(height: 20),
				nameView,
				.space(height: 10),
				progressLabels,
				.space(height: 10),
				.slider(progress: Float(position), max: Float(duration), onChange: { .seek($0) }),
				// << elm-cvs-1-4
				.space(height: 20),
				// << elm-fw-dva-1
				.button(text: playing ? .pause : .play, onTap: .togglePlay),
			]),
			// >> elm-fw-dva-1 ...
			.space(width: nil, height: nil)
			// << elm-fw-dva-1
		])
		// >> elm-fw-dva-1
	}
	// >> elm-cvs-1-4
	
	// << elm-cvs-1-3
	var viewController: ViewController<Message> {
		return .viewController(view)
	}
	// << elm-cvs-1-4
}
// >> elm-cvs-1-4
// >> elm-cvs-1-3

func recordViewController<Message>(duration: TimeInterval, onStop: Message) -> ViewController<Message> {
	let rootView: View<Message> = .stackView(views: [
		.space(),
		.stackView(views: [
			.label(text: "Recording", font: .preferredFont(forTextStyle: .body)),
			.space(height: 10),
			.label(text: timeString(duration), font: .preferredFont(forTextStyle: .title1)),
			.space(height: 10),
			.button(text: "Stop", onTap: onStop),
		], distribution: .equalCentering),
		.space(width: nil, height: nil)
	], distribution: .equalCentering)
	return .viewController(rootView)
}

fileprivate extension String {
	static let newRecording = NSLocalizedString("New Recording", comment: "Title for recording view controller")
	static let pause = NSLocalizedString("Pause", comment: "")
	static let resume = NSLocalizedString("Resume playing", comment: "")
	static let play = NSLocalizedString("Play", comment: "")
}

