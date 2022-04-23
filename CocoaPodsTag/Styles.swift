//
//  Styles.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/4/20.
//

import SwiftUI

struct MenuStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .menuStyle(.borderlessButton)
            .padding(4)
            .background(.ultraThickMaterial)
            .background(Color.gray)
            .cornerRadius(2)
            .font(.title3)
    }
}

struct ButtonStyle: ViewModifier {
    var padding: CGFloat = 10
    var cornerRadius: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    Color.blue
                    LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]), startPoint: .top, endPoint: .bottom)
                }
            )
            .foregroundColor(.white)
            .cornerRadius(cornerRadius)
            .buttonStyle(.plain)
    }
}

struct TextFieldStyle: ViewModifier {
    var font: Font = .title3
    var padding: CGFloat = 4
    var cornerRadius: CGFloat = 2
    var bgColor: Color = .gray
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .textFieldStyle(.plain)
            .padding(padding)
            .background(.ultraThickMaterial)
            .background(bgColor)
            .cornerRadius(cornerRadius)
    }
}
