//
//  MyIP.swift
//  pingInfo
//
//  Created by Anton Belousov on 08/12/2018.
//  Copyright © 2018 kp. All rights reserved.
//

import Foundation

func getDataFromUrl(_ url: URL, completion: @escaping (Data?) -> ()) {
    URLCache.shared.removeAllCachedResponses()
    URLCache.shared.diskCapacity = 0
    URLCache.shared.memoryCapacity = 0
    
    let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 15.0)
    
    URLSession.shared.dataTask(with: request) {
        data, _, _ in
        if let data = data {
            completion(data)
        } else {
            completion(nil)
        }
    }.resume()
}

func getCurrentIP(completion: @escaping (String?, String?) -> ()) {
    
    if let checkedUrl = URL(string: "http://extreme-ip-lookup.com/json/") {
        
        getDataFromUrl(checkedUrl, completion: { data in
            
            guard let data = data else {
                completion(nil, nil)
                print(#function, "no data")
                return
            }
            
            guard let parsedObject = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) else {
                completion(nil, nil)
                print(#function, "can't parse json")
                return
            }
            
            guard let jsonIP = parsedObject as? NSDictionary else {
                completion(nil, nil)
                print(#function, "can't read ip from json")
                return
            }
            
            DispatchQueue.main.async {
                let ip      = jsonIP["query"] as? String ?? "IP Unknown"
                let country = jsonIP["country"] as? String ?? "Country Unknown"
                completion(ip, country)
            }
        })
    }
}

func getWiFiAddress() -> String? {
    var address : String?
    
    // Get list of all interfaces on the local machine:
    var ifaddr : UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return nil }
    guard let firstAddr = ifaddr else { return nil }
    
    // For each interface ...
    for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let interface = ifptr.pointee
        
        // Check for IPv4 or IPv6 interface:
        let addrFamily = interface.ifa_addr.pointee.sa_family
        if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
            
            // Check interface name:
            let name = String(cString: interface.ifa_name)
            if  name == "en0" {
                
                // Convert interface address to a human readable string:
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostname)
            }
        }
    }
    freeifaddrs(ifaddr)
    
    return address
}
