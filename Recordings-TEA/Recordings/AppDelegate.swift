import UIKit
import AVFoundation

// << elm-c-1
// << elm-c-2
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	// >> elm-c-2
	// >> elm-c-1

	var window: UIWindow?
	// << elm-c-1 ...
	let driver = Driver<AppState, AppState.Message>(
		AppState(rootFolder: Store.shared.rootFolder),
		update: { state, message in state.update(message) },
		view: { state in state.viewController },
		subscriptions: { state in state.subscriptions })
	let debugger = RemoteDebugger()
	// >> elm-c-1 ...
	
	// << elm-c-2
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		window = UIWindow(frame: UIScreen.main.bounds)
		window?.rootViewController = driver.viewController
		window?.makeKeyAndVisible()
		window?.backgroundColor = .white
//		let decoder = JSONDecoder()
//		debugger.onData = { [driver] data in
//			guard let d = data else { return }
//			guard let result = try? decoder.decode(AppState.self, from: d) else {
//				fatalError("Cannot decode!: \(d)")
//			}
//			DispatchQueue.main.async {
//				driver.changeState(result)
//			}
//		}
		driver.onChange = { [unowned debugger, window] (state, message) in
			var action = ""
			dump(message, to: &action)
			try! debugger.write(action: action, state: state, snapshot: window!)
		}
		return true
	}
	// >> elm-c-2
	
	func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
		return true
	}
	
	func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
		return true
	}
	
	// << elm-sr-1
	func application(_ application: UIApplication, willEncodeRestorableStateWith coder: NSCoder) {
		driver.encodeRestorableState(coder)
	}
	
	func application(_ application: UIApplication, didDecodeRestorableStateWith coder: NSCoder) {
		driver.decodeRestorableState(coder)
	}
	// >> elm-sr-1
	// << elm-c-1
	// << elm-c-2
}
// >> elm-c-2
// >> elm-c-1
