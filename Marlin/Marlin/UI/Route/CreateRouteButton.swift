//
//  CreateRouteButton.swift
//  Marlin
//
//  Created by Daniel Barela on 8/15/23.
//

import SwiftUI

struct CreateRouteButton: View {
    var showText: Bool = false
    var body: some View {
        NavigationLink(value: MarlinRoute.createRoute) {
            Label(
                title: {
                    if showText {
                        Text("Create Route")
                    }
                },
                icon: { Image(systemName: "arrow.triangle.turn.up.right.diamond")
                        .renderingMode(.template)
                }
            )
        }
        .isDetailLink(false)
        .fixedSize()
        .modifier(ConditionalButtonStyle(hasText: showText))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Create Route Button")
        .padding(16)
    }
}

struct ConditionalButtonStyle: ViewModifier {
    let hasText: Bool
    
    @ViewBuilder func body(content: Content) -> some View {
        if hasText {
            content.buttonStyle(MaterialButtonStyle(type: .contained))
        } else {
            content.buttonStyle(
                MaterialFloatingButtonStyle(
                    type: .secondary,
                    size: .mini,
                    foregroundColor: Color.onPrimaryColor,
                    backgroundColor: Color.primaryColor
                )
            )
        }
    }
}
