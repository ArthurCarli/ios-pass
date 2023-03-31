//
// OptionRow.swift
// Proton Pass - Created on 31/03/2023.
// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.

import SwiftUI
import UIComponents

let kOptionRowCompactHeight = 60

struct OptionRow<Content: View, LeadingView: View, TrailingView: View>: View {
    let action: (() -> Void)?
    let title: String?
    let height: CGFloat
    let content: Content
    let leading: LeadingView
    let trailing: TrailingView

    init(action: (() -> Void)? = nil,
         title: String? = nil,
         height: CGFloat = 76,
         @ViewBuilder content: () -> Content,
         @ViewBuilder leading: (() -> LeadingView) = { EmptyView() },
         @ViewBuilder trailing: (() -> TrailingView) = { EmptyView() }) {
        self.action = action
        self.title = title
        self.height = height
        self.content = content()
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    realBody
                }
                .buttonStyle(.plain)
            } else {
                realBody
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
    }

    private var realBody: some View {
        HStack {
            leading

            VStack(alignment: .leading, spacing: 4) {
                if let title {
                    Text(title)
                        .sectionTitleText()
                }
                content
            }

            Spacer()

            trailing
        }
        .contentShape(Rectangle())
        .frame(height: height)
    }
}

struct TextOptionRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        OptionRow(action: action,
                  content: { Text(title) },
                  trailing: { ChevronRight() })
    }
}

struct ChevronRight: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .resizable()
            .scaledToFit()
            .frame(height: 12)
            .foregroundColor(Color(.tertiaryLabel))
    }
}
