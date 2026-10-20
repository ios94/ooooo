//
//  InstallProgressView.swift
//  AshteMobile
//
//  Created by samara on 23.04.2025.
//  Ksign-Inspired Transparent Sheet UI (Top Padding Fixed)
//

import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. بەشی سەرەوە: ئایکۆن و زانیارییەکان
            HStack(spacing: 16) {
                // ئایکۆنی ئەپەکە لەگەڵ ئیفێکتی تاریکبوون
                ZStack(alignment: .trailing) {
                    FRAppIconView(app: app)
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // ئەو پەردە تاریکەی سەر ئایکۆنەکە کە بەپێی دابەزین لا دەچێت
                    if !viewModel.isCompleted {
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            // پانییەکەی کەم دەبێتەوە کاتێک سەدییەکە زیاد دەکات
                            .frame(width: 70 * (1.0 - CGFloat(viewModel.overallProgress)))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .animation(.spring(), value: viewModel.overallProgress)
                    }
                }
                
                // ناو و دۆخی بەرنامەکە
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.isCompleted ? "Install Complete" : "Preparing Install")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("AshteMobile")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    // ئایکۆن و تێکستی دۆخەکە (پەیام ناردن یان تەواوبوون)
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isCompleted ? "checkmark.square.fill" : "paperplane.fill")
                            .font(.system(size: 12))
                        
                        Text(viewModel.isCompleted ? "Completed" : "Sending Manifest")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(viewModel.isCompleted ? .teal : .orange)
                    .padding(.top, 2)
                }
                
                Spacer()
            }
            
            // 2. هێڵی پێشکەوتن (دەدرەوشێتەوە)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // باکگراوندی هێڵەکە
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    
                    // هێڵە ڕەنگاوڕەنگەکە
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: viewModel.isCompleted ? [.blue, .cyan] : [.orange, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(viewModel.overallProgress))
                        // درەوشانەوە (Glow) بەپێی دۆخەکە
                        .shadow(color: viewModel.isCompleted ? Color.cyan.opacity(0.4) : Color.purple.opacity(0.4), radius: 6, x: 0, y: 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.overallProgress)
                }
            }
            .frame(height: 8)
            
            // 3. بەشی خوارەوە: ڕێژەی سەدی و ڕێنمایی
            HStack {
                Text("\(Int(viewModel.overallProgress * 100))%")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(viewModel.isCompleted ? .teal : .orange)
                
                Spacer()
                
                Text(viewModel.isCompleted ? "Ready to open" : "Keep AshteMobile open")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 45) 
        // 💡 تەنها ئەم دێڕەم گۆڕیوە: بۆشایی سەرەوەم زیاد کرد بۆ ئەوەی لەو هێمایە دوور بکەوێتەوە
        .padding(.top, 30) 
    }
}
