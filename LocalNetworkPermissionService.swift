//
//  LocalNetworkPermissionService.swift
//  Arkade
//
//  Created by user on 25.09.2020.
//  Copyright © 2020 ArkadeGames. All rights reserved.
//

import Foundation
import Network

#warning("Custom warning: Dummy outgoing connection, waiting for permission API")
class LocalNetworkPermissionService {
    
    private let host: String
    private let port: UInt16
    
    private var connection: NWConnection?
    
    init() {
        self.host = "0.0.0.0"
        self.port = 5000
    }
    
    deinit {
        connection?.cancel()
    }
    
    func checkPermission(completion: @escaping (_ isGranted: Bool) -> Void) {
        let host = NWEndpoint.Host(self.host)
        let port = NWEndpoint.Port(integerLiteral: self.port)
        connection = NWConnection(host: host, port: port, using: .udp)
        connection?.stateUpdateHandler = { [weak self] state in
            self?.stateUpdateHandler(state, completion: completion)
        }
        connection?.start(queue: .main)
    }
    
    func stateUpdateHandler(_ state: NWConnection.State, completion: @escaping (Bool) -> Void) {
        print("state: \(state)")
        switch state {
        case .waiting(let error):
            debugPrint(error)
            let content = "content".data(using: .utf8)
            self.connection?.send(content: content, completion: .idempotent)
            completion(false)
        case .ready:
            completion(true)
        default:
            break
        }
    }
    
}
