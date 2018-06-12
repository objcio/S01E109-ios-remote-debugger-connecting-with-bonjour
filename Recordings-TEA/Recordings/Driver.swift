import UIKit

// << elm-fw-dva-3
final class Driver<Model, Message> where Model: Codable, Model: Equatable {
	// >> elm-fw-dva-3
	private var model: Model
	private var strongReferences: StrongReferences = StrongReferences()
	private var subscriptionManager: SubscriptionManager<Message>!
	private(set) var viewController: UIViewController = UIViewController()
	
	private let updateState: (inout Model, Message) -> [Command<Message>]
	private let computeView: (Model) -> ViewController<Message>
	private let fetchSubscriptions: (Model) -> [Subscription<Message>]
	private var player: Player?
	
	var onChange: ((Model, Message) -> ())?
	
	// << elm-fw-dva-3
	init(_ initial: Model, update: @escaping (inout Model, Message) -> [Command<Message>], view: @escaping (Model) -> ViewController<Message>, subscriptions: @escaping (Model) -> [Subscription<Message>], initialCommands: [Command<Message>] = []) {
		// >> elm-fw-dva-3 ...
		viewController.restorationIdentifier = "objc.io.root"
		model = initial
		self.updateState = update
		self.computeView = view
		self.fetchSubscriptions = subscriptions
		// << elm-fw-dva-3
		strongReferences = view(model).render(callback: self.asyncSend, change: &viewController)
		// >> elm-fw-dva-3 ...
		self.subscriptionManager = SubscriptionManager(self.asyncSend)
		self.subscriptionManager.update(subscriptions: fetchSubscriptions(model), player: player)
		for command in initialCommands {
			interpret(command: command)
		}
		// << elm-fw-dva-3
	}
	// >> elm-fw-dva-3 ...
	
	// << elm-fw-dva-4 Driver
	func asyncSend(action: Message) {
		DispatchQueue.main.async { [unowned self] in
			self.run(action: action)
		}
	}
	
	func changeState(_ state: Model) {
		assert(Thread.current.isMainThread)
		model = state
		refresh()
	}

	// << elm-fw-hc-2 Driver
	func run(action: Message) {
		assert(Thread.current.isMainThread)
		let commands = updateState(&model, action)
		// >> elm-fw-dva-4 ...
		refresh()
		onChange?(model, action)
		for command in commands {
			interpret(command: command)
		}
		// << elm-fw-dva-4
	}
	// >> elm-fw-dva-4

	func interpret(command: Command<Message>) {
		command.run(Context(viewController: viewController, send: self.asyncSend, setPlayer: { p in
			self.player = p
		}, player: { self.player }))
	}
	// >> elm-fw-hc-2
	
	func refresh() {
		subscriptionManager.update(subscriptions: fetchSubscriptions(model), player: player)
		strongReferences = computeView(model).render(callback: self.asyncSend, change: &viewController)
	}
	
	func encodeRestorableState(_ coder: NSCoder) {
		let jsonData = try! JSONEncoder().encode(model)
		coder.encode(jsonData, forKey: "data")
	}
	
	func decodeRestorableState(_ coder: NSCoder) {
		if let jsonData = coder.decodeObject(forKey: "data") as? Data {
			if let m = try? JSONDecoder().decode(Model.self, from: jsonData) {
				model = m
			}
		}
		refresh()
	}
	// << elm-fw-dva-3
}
// >> elm-fw-dva-3
