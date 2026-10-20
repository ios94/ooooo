//
//  NBList.swift
//  NimbleKit
//
//  Created by samara on 7.05.2025.
//

import SwiftUI

public struct NBList<Content>: View where Content: View {
	public enum NBListType {
		case list
		case form
	}
	
	private var _title: String
	private var _mode: NavigationBarItem.TitleDisplayMode
	private var _type: NBListType
	private var _content: Content
	
	public init(
		_ title: String,
		displayMode: NavigationBarItem.TitleDisplayMode = .automatic,
		type: NBListType = .form,
		@ViewBuilder content: () -> Content
	) {
		self._title = title
		self._mode = displayMode
		self._type = type
		self._content = content()
	}
	
	public var body: some View {
		Group {
			switch _type {
			case .form:
				Form {
					_content
				}
			case .list:
				List {
					_content
				}
			}
		}
		.scrollContentBackground(.hidden)
		.background(NBColorfulBackground())
		.navigationTitle(_title)
		.navigationBarTitleDisplayMode(_mode)
	}
}

// MARK: - Soft colorful background shared by every list/form screen
struct NBColorfulBackground: View {
	private func _color(_ hex: UInt32) -> Color {
		Color(
			.sRGB,
			red: Double((hex >> 16) & 0xFF) / 255,
			green: Double((hex >> 8) & 0xFF) / 255,
			blue: Double(hex & 0xFF) / 255,
			opacity: 1
		)
	}
	
	var body: some View {
		ZStack {
			Color(UIColor.systemGroupedBackground)
			
			Circle()
				.fill(_color(0x7C5CFF).opacity(0.22))
				.frame(width: 320, height: 320)
				.blur(radius: 90)
				.offset(x: -140, y: -300)
			
			Circle()
				.fill(_color(0xFF4F9A).opacity(0.18))
				.frame(width: 300, height: 300)
				.blur(radius: 90)
				.offset(x: 160, y: -120)
			
			Circle()
				.fill(_color(0x19C9F3).opacity(0.16))
				.frame(width: 320, height: 320)
				.blur(radius: 100)
				.offset(x: -120, y: 360)
		}
		.ignoresSafeArea()
		.allowsHitTesting(false)
	}
}
