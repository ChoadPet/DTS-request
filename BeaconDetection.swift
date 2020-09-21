//
//  BeaconDetection.swift
//  Arkade
//
//  Created by user on 11.06.2020.
//  Copyright © 2020 ArkadeGames. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class BeaconDetection: NSObject {
    
    var computerHandler: ((PersonalComputer) -> Void)?
    
    private let queue: DispatchQueue
    private let port: UInt16
    
    private var socket: GCDAsyncUdpSocket?

    
    init(port: UInt16) {
        self.port = port
        self.queue = .main
        super.init()
    }
    
    deinit {
        closeSocket()
    }
    
    func bindSocket() {
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: queue)
        do {
            try socket!.bind(toPort: port)
        } catch let error {
            debugPrint("Exception when \(#function): \(error)")
        }
    }
    
    func beginReceiving() {
        do {
            try socket?.beginReceiving()
        } catch let error {
            debugPrint("Exception when \(#function): \(error)")
        }
    }
    
    func closeSocket() {
        socket?.close()
    }
    
    // MARK: Private API
    
    private func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.map { String(text[Range($0.range, in: text)!]) }
        } catch let error {
            debugPrint("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
}


extension BeaconDetection: GCDAsyncUdpSocketDelegate {
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        let name = String(data: data, encoding: .utf8)!
        let junkyHost = GCDAsyncUdpSocket.host(fromAddress: address) ?? "0.0.0.0"
        let ipAddress = matches(for: "[0-9.]", in: junkyHost).joined()
        let pc = PersonalComputer(name: name, ipAddress: ipAddress)
        debugPrint("Address: \(ipAddress), Data: \(name)")
        computerHandler?(pc)
    }
}
