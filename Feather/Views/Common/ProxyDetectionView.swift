import SwiftUI

struct ProxyDetectionView: View {
    @ObservedObject var monitor: NetworkMonitor
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // ئایکۆنە سوورەکەی ئاگادارکردنەوە
                ZStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 110))
                        .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
                        .shadow(color: Color.red.opacity(0.4), radius: 25, x: 0, y: 0)
                    
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 45))
                        .foregroundColor(.gray.opacity(0.8))
                        .offset(x: -25, y: -50)
                }
                .padding(.bottom, 20)
                
                Text("Proxy Detected!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Proxy settings detected on your device.\nPlease disable the proxy to continue.")
                    .font(.system(size: 16))
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                VStack(spacing: 8) {
                    Text("Detected Proxy Type")
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray)
                    
                    Text(monitor.proxyType.isEmpty ? "Unknown" : monitor.proxyType)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color(white: 0.2))
                        .clipShape(Capsule())
                }
                .padding(.top, 20)
                
                Spacer()
                
                // دوگمەی Re-check
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    monitor.checkProxyAndVPN()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .bold))
                        Text("Re-check")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                
                Text("How to disable the proxy:\nGo to Settings or your VPN app and disable the proxy.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 30)
                    .padding(.top, 10)
            }
        }
    }
}
