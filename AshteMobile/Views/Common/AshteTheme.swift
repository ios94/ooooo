//
//  AshteTheme.swift
//  AshteMobile
//
//  Colorful & youthful design system shared by every screen.
//  (File-system synchronized group: no Xcode project edit needed.)
//

import SwiftUI

// MARK: - Palette
enum AshteTheme {
	static let violet = Color(ashteHex: 0x7C5CFF)
	static let pink   = Color(ashteHex: 0xFF4F9A)
	static let orange = Color(ashteHex: 0xFF9F1C)
	static let cyan   = Color(ashteHex: 0x19C9F3)
	static let mint   = Color(ashteHex: 0x2ED8A3)
	static let sun    = Color(ashteHex: 0xFFD23F)
	
	/// Main brand gradient (violet → pink)
	static let primary = LinearGradient(
		colors: [violet, pink],
		startPoint: .topLeading, endPoint: .bottomTrailing
	)
	static let sunset = LinearGradient(
		colors: [pink, orange],
		startPoint: .topLeading, endPoint: .bottomTrailing
	)
	static let ocean = LinearGradient(
		colors: [cyan, violet],
		startPoint: .topLeading, endPoint: .bottomTrailing
	)
	static let fresh = LinearGradient(
		colors: [mint, cyan],
		startPoint: .topLeading, endPoint: .bottomTrailing
	)
	static let candy = LinearGradient(
		colors: [violet, pink, orange],
		startPoint: .topLeading, endPoint: .bottomTrailing
	)
	
	/// Gradients used in rotation for rows/badges so lists feel lively.
	static let rotation: [LinearGradient] = [primary, ocean, sunset, fresh]
	
	static func gradient(at index: Int) -> LinearGradient {
		rotation[((index % rotation.count) + rotation.count) % rotation.count]
	}
}

// MARK: - Color helper
extension Color {
	/// 0xRRGGBB initializer (named differently to avoid clashing with `init(hex: String)`).
	init(ashteHex value: UInt32, opacity: Double = 1) {
		self.init(
			.sRGB,
			red:   Double((value >> 16) & 0xFF) / 255,
			green: Double((value >> 8) & 0xFF) / 255,
			blue:  Double(value & 0xFF) / 255,
			opacity: opacity
		)
	}
}

// MARK: - Background (soft colorful blobs)
struct AshteBackground: View {
	var body: some View {
		ZStack {
			Color(UIColor.systemGroupedBackground)
			
			Circle()
				.fill(AshteTheme.violet.opacity(0.22))
				.frame(width: 320, height: 320)
				.blur(radius: 90)
				.offset(x: -140, y: -300)
			
			Circle()
				.fill(AshteTheme.pink.opacity(0.18))
				.frame(width: 300, height: 300)
				.blur(radius: 90)
				.offset(x: 160, y: -120)
			
			Circle()
				.fill(AshteTheme.cyan.opacity(0.16))
				.frame(width: 320, height: 320)
				.blur(radius: 100)
				.offset(x: -120, y: 360)
		}
		.ignoresSafeArea()
		.allowsHitTesting(false)
	}
}

// MARK: - Card
struct AshteCardModifier: ViewModifier {
	var cornerRadius: CGFloat = 22
	var tint: Color = AshteTheme.violet
	
	func body(content: Content) -> some View {
		content
			.background(Color(UIColor.secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
					.strokeBorder(tint.opacity(0.12), lineWidth: 1)
			)
			.shadow(color: tint.opacity(0.12), radius: 12, x: 0, y: 6)
	}
}

extension View {
	func ashteCard(cornerRadius: CGFloat = 22, tint: Color = AshteTheme.violet) -> some View {
		modifier(AshteCardModifier(cornerRadius: cornerRadius, tint: tint))
	}
	
	/// Colorful background behind lists / forms / scroll views.
	func ashteScreenBackground() -> some View {
		self
			.scrollContentBackground(.hidden)
			.background(AshteBackground())
	}
}

// MARK: - Gradient button style
struct AshteGradientButtonStyle: ButtonStyle {
	var gradient: LinearGradient = AshteTheme.primary
	var shadowColor: Color = AshteTheme.violet
	var horizontalPadding: CGFloat = 22
	var verticalPadding: CGFloat = 9
	
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.font(.system(size: 15, weight: .heavy, design: .rounded))
			.foregroundColor(.white)
			.padding(.horizontal, horizontalPadding)
			.padding(.vertical, verticalPadding)
			.background(gradient)
			.clipShape(Capsule())
			.shadow(color: shadowColor.opacity(0.35), radius: 8, x: 0, y: 4)
			.scaleEffect(configuration.isPressed ? 0.94 : 1)
			.animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
	}
}

// MARK: - Icon badge
struct AshteIconBadge: View {
	let systemName: String
	var gradient: LinearGradient = AshteTheme.primary
	var size: CGFloat = 32
	
	var body: some View {
		Image(systemName: systemName)
			.font(.system(size: size * 0.46, weight: .bold))
			.foregroundColor(.white)
			.frame(width: size, height: size)
			.background(gradient)
			.clipShape(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
			.shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 2)
	}
}

// MARK: - Section title
struct AshteSectionTitle: View {
	let title: String
	var count: Int? = nil
	var gradient: LinearGradient = AshteTheme.primary
	
	var body: some View {
		HStack(spacing: 10) {
			Capsule()
				.fill(gradient)
				.frame(width: 5, height: 22)
			
			Text(title)
				.font(.system(.title2, design: .rounded).weight(.heavy))
				.foregroundColor(.primary)
			
			Spacer()
			
			if let count {
				Text("\(count)")
					.font(.system(size: 14, weight: .heavy, design: .rounded))
					.foregroundColor(.white)
					.padding(.horizontal, 12)
					.padding(.vertical, 5)
					.background(gradient)
					.clipShape(Capsule())
			}
		}
	}
}

// MARK: - Empty state
struct AshteEmptyState: View {
	let icon: String
	let title: String
	let message: String
	var buttonTitle: String? = nil
	var action: (() -> Void)? = nil
	
	var body: some View {
		VStack(spacing: 16) {
			Image(systemName: icon)
				.font(.system(size: 54, weight: .bold))
				.foregroundStyle(AshteTheme.candy)
				.frame(width: 110, height: 110)
				.background(
					Circle().fill(AshteTheme.violet.opacity(0.12))
				)
			
			Text(title)
				.font(.system(.title2, design: .rounded).weight(.heavy))
				.multilineTextAlignment(.center)
			
			Text(message)
				.font(.subheadline)
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 30)
			
			if let buttonTitle, let action {
				Button(action: action) {
					HStack(spacing: 8) {
						Image(systemName: "plus.circle.fill")
						Text(buttonTitle)
					}
				}
				.buttonStyle(AshteGradientButtonStyle(horizontalPadding: 26, verticalPadding: 13))
				.padding(.top, 6)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding()
	}
}
