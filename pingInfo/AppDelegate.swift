//
//  AppDelegate.swift
//  pingInfo
//
//  Created by Anton Belousov on 08/12/2018.
//  Copyright © 2018 kp. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    let ipItem      = NSMenuItem(title: "IP", action: nil, keyEquivalent: "")
    let countryItem = NSMenuItem(title: "Country", action: nil, keyEquivalent: "")

    var waiting = false
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        setPingStatusTitle("Idle")
        start()
        constructMenu()
    }
    
    func setPingStatusTitle(_ title: String) {
        DispatchQueue.main.async {
            if let button = self.statusItem.button {
                button.title = title
            }
        }
    }
    
    func setIPTitle(_ title: String) {
        DispatchQueue.main.async {
            self.ipItem.title = title
        }
    }
    
    func setCountry(_ country: String) {
        DispatchQueue.main.async {
            self.countryItem.title = country
        }
    }
    
    @objc func printQuote(_ sender: Any?) {
        let quoteText = "Never put off until tomorrow what you can do the day after tomorrow."
        let quoteAuthor = "Mark Twain"
        
        print("\(quoteText) — \(quoteAuthor)")
    }
    
    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(ipItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(countryItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func start() {
        if waiting {
            return
        }
        waiting = true
        pingOnce { result_ms in
            self.waiting = false
            if let result_ms = result_ms {
                let title = String(format: "%.1f", result_ms)
                self.setPingStatusTitle(title)
            } else {
                self.setPingStatusTitle("Offline")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.start()
            })
        }
        
        DispatchQueue.global().async {
            getCurrentIP { ip, country in
                guard let ip = ip, let country = country else {
                    return
                }
                self.setIPTitle(ip)
                self.setCountry(country)
            }
        }
    }
}

func pingOnce(completion: @escaping (Double?) -> ()) {
    
    PlainPing.ping("www.google.com", withTimeout: 1.0, completionBlock: { (latency: Double?, error: Error?) in

        if let latency = latency {
            print("latency (ms): \(latency)")
            completion(latency)
            return
        }

        if let error = error {
            print("error: \(error.localizedDescription)")
        }
        completion(nil)
    })
}

func pingOnce2(completion: @escaping (Double?) -> ()) {
    let begin = Date()
    URLSession.shared.dataTask(with: URL(string: "https://ya.ru")!) { (data, response, error) in
        if let error = error {
            print("error: ", error)
            completion(nil)
            return
        }
        
        if let response = response as? HTTPURLResponse {
            let statusCode = response.statusCode
            if statusCode >= 400 || statusCode < 200 {
                print("statusCode: ", statusCode)
                completion(nil)
                return
            }
        }
        
        if data == nil {
            print("no data loaded")
            completion(nil)
            return
        }
        let duration = -begin.timeIntervalSinceNow * 1000
        completion(duration)
        }.resume()
}

