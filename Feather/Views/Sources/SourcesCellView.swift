//
//  SourcesCellView.swift
//  AshteMobile
//

import SwiftUI
import NimbleViews
import NukeUI

// MARK: - View
struct SourcesCellView: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	
	var source: AltSource
	
	// MARK: Body
	var body: some View {
		let isRegular = horizontalSizeClass != .compact
		
		FRIconCellView(
			title: source.name ?? .localized("Unknown"),
			subtitle: "", // لێرەدا لینکەکەمان سڕییەوە بۆ ئەوەی بە هیچ شێوەیەک دیار نەبێت
			iconUrl: source.iconURL
		)
		.padding(isRegular ? 12 : 0)
		.background(
			isRegular
			? RoundedRectangle(cornerRadius: 18, style: .continuous)
				.fill(AshteTheme.violet.opacity(0.08))
			: nil
		)
		.swipeActions {
			_actions(for: source)
            // دوگمەی کۆپیکردنمان لە کاتی ڕاکێشاندا لابرد
		}
		.contextMenu {
			_actions(for: source)
            // دوگمەی کۆپیکردنمان لە کاتی پەنجە پێداگرتن (Long Press) لابرد
		}
	}
}

// MARK: - Extension: View
extension SourcesCellView {
	@ViewBuilder
	private func _actions(for source: AltSource) -> some View {
		Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
			Storage.shared.deleteSource(for: source)
		}
	}
}
