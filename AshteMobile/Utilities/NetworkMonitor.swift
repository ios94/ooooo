import Foundation
import Combine

class NetworkMonitor: ObservableObject {
    @Published var isProxied: Bool = false
    @Published var proxyType: String = ""
    
    init() {
        checkProxyAndVPN()
    }
    
    func checkProxyAndVPN() {
        guard let unmanagedSettings = CFNetworkCopySystemProxySettings() else { return }
        let settings = unmanagedSettings.takeRetainedValue() as? [String: Any] ?? [:]
        
        // ١. پشکنینی پرۆکسی
        if settings.keys.contains("HTTPProxy") || settings.keys.contains("HTTPSProxy") {
            DispatchQueue.main.async {
                self.isProxied = true
                self.proxyType = "HTTP Proxy"
            }
            return
        }
        
        // ٢. پشکنینی ڤی‌پی‌ئێن (VPN)
        if let scoped = settings["__SCOPED__"] as? [String: Any] {
            let vpnNames = ["tap", "tun", "ppp", "ipsec", "utun"]
            for interface in scoped.keys {
                for name in vpnNames {
                    if interface.contains(name) {
                        DispatchQueue.main.async {
                            self.isProxied = true
                            self.proxyType = "VPN"
                        }
                        return
                    }
                }
            }
        }
        
        // ئەگەر هیچیان نەبوون
        DispatchQueue.main.async {
            self.isProxied = false
            self.proxyType = ""
        }
    }
}
