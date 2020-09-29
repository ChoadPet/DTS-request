import Foundation
import Network

#warning("Custom warning: Dummy outgoing connection, waiting for permission API")
class LocalNetworkPermissionService {
    
    private var host: String?
    private let port: UInt16
    
    private var connection: NWConnection?
    
    init() {
        self.port = 12345
        self.host = getWiFiAddress()
    }
    
    deinit {
        connection?.cancel()
    }
    
    // This method try to connect to iPhone self IP Address
    func triggerDialog() {
        guard self.host != nil else { return assertionFailure("Hmm... no IP-Address?") }
        let host = NWEndpoint.Host(self.host!)
        let port = NWEndpoint.Port(integerLiteral: self.port)
        connection = NWConnection(host: host, port: port, using: .udp)
        connection?.stateUpdateHandler = { [weak self] state in
            self?.stateUpdateHandler(state)
        }
        connection?.start(queue: .main)
    }
    
    func stateUpdateHandler(_ state: NWConnection.State) {
        print("state: \(state)")
        switch state {
        case .waiting(let error):
            debugPrint(error)
            let content = "Hello Cruel World!".data(using: .utf8)
            self.connection?.send(content: content, completion: .idempotent)
        default:
            break
        }
    }
    
    // From: https://stackoverflow.com/a/30754194/6057764
    // Return IP address of WiFi interface (en0) as a String, or `nil`
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
    
}
