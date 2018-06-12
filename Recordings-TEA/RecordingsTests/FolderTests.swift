import XCTest
@testable import Recordings

let rootUuid = UUID()
let uuid1 = UUID()
let uuid2 = UUID()
let uuid3 = UUID()
let uuid4 = UUID()
let uuid5 = UUID()

let folder1 = Folder(name: "Child 1", uuid: uuid1, items: [
	.folder(Folder(name: "Child 2", uuid: uuid2, items: [])),
	.recording(Recording(name: "Recording 2", uuid: uuid4))
	])
let recording1 = Recording(name: "Recording 1", uuid: uuid3)

func constructTestFolder() -> Folder {
	return Folder(name: "Recordings", uuid: rootUuid, items: [
		.folder(folder1),
		.recording(recording1)
	])
}

let sampleURL = URL(fileURLWithPath: "")
let sampleRecorder = Recorder(url: sampleURL)!

class RecordingsTests: XCTestCase {
	
	// << elm-folder-listing-test
	func testFolderListing() {
		// Construct the AppState
		let vc = AppState(rootFolder: constructTestFolder()).viewController
		
		// Traverse and check hierarchy
		guard case .splitViewController(let svc, _) = vc else { XCTFail(); return }
		let navController = svc.left(nil)
		let navItem = navController.viewControllers[0]
		XCTAssertEqual(navItem.title, "Recordings")
		guard case .tableViewController(let view) = navItem.viewController else { XCTFail(); return }
		
		// Check structure
		XCTAssertEqual(view.items.count, 2)

		XCTAssertEqual(view.items[0].text, "📁  Child 1")
		XCTAssertEqual(view.items[0].onSelect, .selectFolder(folder1))

		XCTAssertEqual(view.items[1].text, "🔊  Recording 1")
		XCTAssertEqual(view.items[1].onSelect, .selectRecording(recording1))
	}
	// >> elm-folder-listing-test
	
	// << elm-folder-selection-test
	func testFolderSelection() {
		// Construct the AppState
		var appState = AppState(rootFolder: constructTestFolder())

		// Test initial conditions
		XCTAssertEqual(appState.folders.map { $0.uuid }, [rootUuid])

		// Push a new folder
		let commands = appState.update(.selectFolder(Folder(name: "Child 1", uuid: uuid1, items: [])))

		// Test results
		XCTAssert(commands.isEmpty)
		XCTAssertEqual(appState.folders.map { $0.uuid }, [rootUuid, uuid1])
	}
	// >> elm-folder-selection-test

	func testFolderRender() {
		// Construct the AppState
		let appState = AppState(rootFolder: constructTestFolder())

		// Traverse hierarchy
		let vc = appState.viewController
		guard case .splitViewController(let svc, _) = vc,
			let navItem = svc.left(nil).viewControllers.first,
			case .tableViewController(let view) = navItem.viewController,
			view.items.count == 2
			else { XCTFail(); return }

		XCTAssertEqual(view.items[0].onSelect!, AppState.Message.selectFolder(folder1))
	}


	func testFolderSelectionIntegrated() {
		// Construct the AppState
		var appState = AppState(rootFolder: constructTestFolder())

		// Test initial conditions
		XCTAssertEqual(appState.folders.map { $0.uuid }, [rootUuid])
		
		// Traverse hierarchy
		let vc = appState.viewController
		guard case .splitViewController(let svc, _) = vc,
			let navItem = svc.left(nil).viewControllers.first,
			case .tableViewController(let view) = navItem.viewController,
			view.items.count == 2
			else { XCTFail(); return }
		
		// Perform a command
		guard case .selectFolder(let folder)? = view.items[0].onSelect else { XCTFail(); return }
		let commands = appState.update(.selectFolder(folder))
		
		// Test results
		XCTAssert(commands.isEmpty)
		XCTAssertEqual(appState.folders.map { $0.uuid }, [rootUuid, uuid1])
	}

	// << elm-test-subscription
	func testFolderStoreSubscription() {
		let appState = AppState(rootFolder: constructTestFolder())
		// Test for a store subscription
		guard case let .storeChanged(message)? = appState.subscriptions.first
			else { XCTFail(); return }
		
		// Test that the message is a `.reloadFolder`
		let updatedFolder = Folder(name: "TestFolderName", uuid: uuid5)
		XCTAssertEqual(message(updatedFolder), .storeChanged(updatedFolder))
	}
	// >> elm-test-subscription
	
	// << elm-test-commands
	func testCommands() {
		var state = RecordState(folder: folder1, recorder: sampleRecorder)

		let commands: [CommandEnum<RecordState.Message>] = state.update(.save(name: nil))
		XCTAssert(commands.isEmpty)

		let commands1: [CommandEnum<RecordState.Message>] = state.update(.save(name: "Hello"))
		guard case ._saveRecording(name: "Hello",
											folder: folder1,
											url: sampleRecorder.url)? = commands1.first else {
			XCTFail(); return
		}
	}
	// >> elm-test-commands
}
