//
//  ViewController.swift
//  UnidirectionalDebugger
//
//  Created by Chris Eidhof on 21.02.18.
//  Copyright © 2018 objc.io. All rights reserved.
//

import Cocoa

final class Pair: NSObject {
    let key: Any
    let value: Any
    init(key: Any, _ value: Any) {
        self.key = key
        self.value = value
        super.init()
    }
}

class ArrayDataSource: NSObject, NSTableViewDataSource {
    var items: [Any] = [] {
        didSet {
            tableView.reloadData()
            tableView.scrollToEndOfDocument(nil)
        }
    }
    
    unowned var tableView: NSTableView
    init(tableView: NSTableView) {
        self.tableView = tableView
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }
 
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return items[row]
    }
}

class JSONDataSource: NSObject, NSOutlineViewDataSource {
    var value: Any {
        didSet {
            outlineView.reloadData()
        }
    }
    unowned var outlineView: NSOutlineView
    
    convenience init?(string: String, outlineView: NSOutlineView) {
        guard let obj = try? JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: []) else {
            return nil
        }
        self.init(obj, outlineView: outlineView)
    }
    init(_ value: Any, outlineView: NSOutlineView) {
        self.value = value
        self.outlineView = outlineView
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem theItem: Any?) -> Any {
        let item = theItem ?? value
        if let arr = item as? NSArray {
            return Pair(key: index as NSNumber, arr[index])
        } else if let dict = item as? NSDictionary {
            let key = dict.allKeys[index]
            return Pair(key: key, dict[key]!)
        } else if let pair = item as? Pair {
            return self.outlineView(outlineView, child: index, ofItem: pair.value)
        } else {
            return NSNull()
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem theItem: Any?) -> Int {
        let item = theItem ?? value
        if let arr = item as? NSArray {
            return arr.count
        } else if let dict = item as? NSDictionary {
            return dict.count
        } else if let pair = item as? Pair {
            return self.outlineView(outlineView, numberOfChildrenOfItem: pair.value)
        } else {
            return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if item is NSArray { return true }
        else if item is NSDictionary { return true }
        else if let a = item as? Pair {
            return self.outlineView(outlineView, isItemExpandable: a.value)
        }
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if item is NSArray {
            return nil
        } else if item is NSDictionary {
            return nil
        } else if let str = item as? NSString {
            return str
        } else if let num = item as? NSNumber {
            return num
        } else if let pair = item as? Pair {
            if tableColumn?.title == "Value" {
                return self.outlineView(outlineView, objectValueFor: tableColumn, byItem: pair.value)
            } else {
                return pair.key
            }
        } else if item is NSNull {
            return item
        }
        fatalError("\(item as Any)")
    }
}

let sample = "{}"

class ViewController: NSViewController, NSTableViewDelegate {
    var service: DebugServer!
    
    @IBOutlet var textView: NSTextView?
    
    @IBOutlet var actions: NSTableView! {
        didSet {
            actionsDataSource = ArrayDataSource(tableView: actions)
            actions.dataSource = actionsDataSource
            actions.delegate = self
        }
    }
    @IBOutlet var outlineView: NSOutlineView! {
        didSet {
            dataSource = JSONDataSource(string: "{}", outlineView: outlineView)
            service = DebugServer { [unowned self] value in
                DispatchQueue.main.async {
                    guard let dict = value as? [String:Any],
                    let state = dict["state"], let action = dict["action"] as? String,
                    let imageDataStr = dict["imageData"] as? String
                    
                    else { print("Unknown value: \(value)"); return }
                    let data = Data(base64Encoded: imageDataStr)!
                    let image = NSImage(data: data)!
                    self.history.append((action,state, image))
                }
            }
            outlineView.dataSource = dataSource
        }
    }

    @IBOutlet var imageView: NSImageView!
    
    var dataSource: JSONDataSource!
    var history: [(String, Any, NSImage)] = [] {
        didSet {
            actionsDataSource?.items = history.map { $0.0 }
            actions.selectRowIndexes(IndexSet(integer: history.count-1), byExtendingSelection: false)
        }
    }
    var selection: (String, Any, NSImage)? {
        return actions.selectedRow >= 0 ? history[actions.selectedRow] : nil
    }
    var actionsDataSource: ArrayDataSource!
    
    @IBAction func resetToState(_ sender: Any) {
        guard let s = selection else { return }
        service.write(json: s.1)
    }
    
    @IBAction func sliderChanged(_ sender: NSSlider) {
        print(sender.intValue)
    }
    
    override func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        return selection != nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outlineView.expandItem(nil, expandChildren: true)
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let s = selection else { return }
        textView?.string = s.0
        dataSource.value = s.1
        //outlineView.expandItem(nil, expandChildren: true)
        imageView.image = s.2
    }
}

