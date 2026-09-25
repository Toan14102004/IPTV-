//
//  CustomAlertView.swift
//  I340_IPTV
//
//  Created by Toan Nguyen on 11/12/24.
//

import Foundation
import SwiftUI

struct CustomAlertView<Content: View>: View {
    var icon: Image?
    let title: LocalizedStringKey?
    var titleColor: Color = Color.white
    var description: LocalizedStringKey?
    var descriptionColor: Color = Color.textSecondary
    
    var background: Color = Color.surface
    var showLine: Bool = false
    var buttonAxis: Axis = .horizontal
    
    var cancelActionTitle: LocalizedStringKey?
    var cancelActionTitleColor: Color = Color.white
    var cancelAction: (() -> Void)?
    
    var isPrimaryActionReady: () -> Bool = { true }
    var primaryActionTitle: LocalizedStringKey?
    var primaryActionTitleColor: Color = Color.black
    var primaryActionBackground: Color = Color.brand
    var primaryAction: (() -> Void)?
    var dismissAction: (() -> Void)?
    
    @ViewBuilder var customContent: () -> Content
    
    var body: some View {
        VStack(spacing: Layout.Spacing.m) {
            // Icon
            if let icon {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: Layout.Icon.xxl, height: Layout.Icon.xxl)
                    .foregroundStyle(Color.brand)
            }
            
            // Title
            if let title {
                Text(title)
                    .font(.system(size: Layout.Text.title3, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .foregroundStyle(titleColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Description
            if let description {
                Text(description)
                    .font(.system(size: Layout.Text.body, weight: .regular))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .foregroundStyle(descriptionColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Custom Content
            customContent()
                .padding(.vertical, Layout.Spacing.xs)
            
            // Buttons
            if buttonAxis == .horizontal {
                if showLine {
                    customDivider()
                        .frame(height: 1)
                }
                
                HStack(spacing: Layout.Spacing.m) {
                    if let cancelAction, let cancelActionTitle {
                        Button {
                            cancelAction()
                            dismissAction?()
                        } label: {
                            Text(cancelActionTitle)
                                .font(.system(size: Layout.Text.body, weight: .semibold))
                                .foregroundStyle(cancelActionTitleColor)
                                .frame(height: Layout.Button.height)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(Layout.CornerRadius.medium)
                                .contentShape(Rectangle())
                        }
                    }
                    
                    if let primaryAction, let primaryActionTitle {
                        Button {
                            if isPrimaryActionReady() {
                                primaryAction()
                                dismissAction?()
                            }
                        } label: {
                            Text(primaryActionTitle)
                                .font(.system(size: Layout.Text.body, weight: .semibold))
                                .foregroundColor(
                                    isPrimaryActionReady() ? primaryActionTitleColor : Color.textSecondary
                                )
                                .frame(height: Layout.Button.height)
                                .frame(maxWidth: .infinity)
                                .background(
                                    isPrimaryActionReady()
                                    ? primaryActionBackground : Color.gray.opacity(0.3)
                                )
                                .cornerRadius(Layout.CornerRadius.medium)
                                .contentShape(Rectangle())
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: Layout.Spacing.s) {
                    if let primaryAction, let primaryActionTitle {
                        Button {
                            if isPrimaryActionReady() {
                                primaryAction()
                                dismissAction?()
                            }
                        } label: {
                            Text(primaryActionTitle)
                                .font(.system(size: Layout.Text.body, weight: .semibold))
                                .foregroundColor(
                                    isPrimaryActionReady() ? primaryActionTitleColor : Color.textSecondary
                                )
                                .frame(height: Layout.Button.height)
                                .frame(maxWidth: .infinity)
                                .background(
                                    isPrimaryActionReady()
                                    ? primaryActionBackground : Color.gray.opacity(0.3)
                                )
                                .cornerRadius(Layout.CornerRadius.medium)
                                .contentShape(Rectangle())
                        }
                    }
                    
                    if let cancelAction, let cancelActionTitle {
                        Button {
                            cancelAction()
                            dismissAction?()
                        } label: {
                            Text(cancelActionTitle)
                                .font(.system(size: Layout.Text.body, weight: .semibold))
                                .foregroundStyle(cancelActionTitleColor)
                                .frame(height: Layout.Button.height)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(Layout.CornerRadius.medium)
                                .contentShape(Rectangle())
                        }
                    }
                }
            }
        }
        .padding(Layout.Spacing.l)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        .background(background)
        .cornerRadius(Layout.CornerRadius.xxl)
        .shadow(
            color: .black.opacity(0.3), radius: Layout.Shadow.largeRadius, x: 0,
            y: Layout.Shadow.mediumOffsetY
        )
        .padding(.horizontal, Layout.Spacing.l)
    }
    
    func customDivider() -> some View {
        Divider().overlay(Color.gray.opacity(0.3))
    }
}

extension CustomAlertView where Content == EmptyView {
    init(
        icon: Image? = nil,
        title: LocalizedStringKey?,
        titleColor: Color = Color.white,
        description: LocalizedStringKey? = nil,
        descriptionColor: Color = Color.textSecondary,
        
        background: Color = Color.surface,
        showLine: Bool = false,
        buttonAxis: Axis = .horizontal,
        
        cancelActionTitle: LocalizedStringKey? = "Cancel",
        cancelActionTitleColor: Color = Color.white,
        cancelAction: (() -> Void)? = nil,
        
        isPrimaryActionReady: @escaping () -> Bool = { true },
        primaryActionTitle: LocalizedStringKey? = "OK",
        primaryActionTitleColor: Color = Color.black,
        primaryActionBackground: Color = Color.brand,
        primaryAction: (() -> Void)? = nil,
        dismissAction _: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.titleColor = titleColor
        self.description = description
        self.descriptionColor = descriptionColor
        
        self.background = background
        self.showLine = showLine
        self.buttonAxis = buttonAxis
        
        self.cancelAction = cancelAction
        self.cancelActionTitleColor = cancelActionTitleColor
        self.cancelActionTitle = cancelActionTitle
        
        self.isPrimaryActionReady = isPrimaryActionReady
        self.primaryActionTitle = primaryActionTitle
        self.primaryActionTitleColor = primaryActionTitleColor
        self.primaryActionBackground = primaryActionBackground
        self.primaryAction = primaryAction
        
        customContent = { EmptyView() }
    }
}

#Preview(body: {
    VStack(spacing: Layout.Spacing.xl) {
        // Alert with both buttons (vertical)
        CustomAlertView(
            icon: Image(systemName: "exclamationmark.triangle.fill"),
            title: "Delete I340_IPTV?",
            description:
                "Are you sure you want to delete this food from your collection? This action cannot be undone.",
            cancelActionTitle: "Cancel",
            cancelAction: {},
            primaryActionTitle: "Delete",
            primaryAction: {}
        )
        
        // Alert with single button
        CustomAlertView(
            icon: Image(systemName: "checkmark.circle.fill"),
            title: "Success!",
            description: "Your food has been added to the collection.",
            primaryActionTitle: "Done",
            primaryAction: {}
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
})
