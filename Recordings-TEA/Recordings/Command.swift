import UIKit

struct Context<Message> {
	let viewController: UIViewController
	let send: (Message) -> ()
	
	// todo the extra state could be dependent on Message?
	// todo accessor?
	let setPlayer: (Player?) -> ()
	let player: () -> Player?
	
	func map<B>(_ transform: @escaping (B) -> Message) -> Context<B> {
		return Context<B>(viewController: viewController, send: {
			self.send(transform($0))
		}, setPlayer: setPlayer, player: player)
	}
}

struct Command<Message> {
	let run: (Context<Message>) -> ()
	
	func map<B>(_ transform: @escaping (Message) -> B) -> Command<B> {
		return Command<B> { context in
			self.run(context.map(transform))
		}
	}
}

// Built-in Commands

// << elm-fw-hc-4
extension Command {
	// >> elm-fw-hc-4 ...
	static func modalTextAlert(title: String, accept: String, cancel: String, placeholder: String, submit: @escaping (String?) -> (Message)) -> Command {
		return Command { context in
			context.viewController.modalTextAlert(title: title, accept: accept, cancel: cancel, placeholder: placeholder, callback: { str in
				context.send(submit(str))
			})
		}
	}
	
	static func modalAlert(title: String, accept: String) -> Command {
		return Command { context in
			let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: accept, style: .default, handler: nil))
			let vc: UIViewController = context.viewController.presentedViewController ?? context.viewController
			vc.present(alert, animated: true, completion: nil)
		}
	}
	
	// << elm-fw-hc-4
	static func request(_ request: URLRequest, available: @escaping (Data?) -> Message) -> Command {
		return Command { context in
			URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error) in
				context.send(available(data))
			}.resume()
		}
	}
}
// >> elm-fw-hc-4
