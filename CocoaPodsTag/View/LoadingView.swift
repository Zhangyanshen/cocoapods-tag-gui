//
//  LoadingView.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/4/23.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(DarkBlueShadowProgressViewStyle())
                .padding(8)
            Text("请稍后...")
                .foregroundColor(.primary)
                .font(.title3)
                .fontWeight(.bold)
                .padding(8)
        }
        .frame(width: 150, height: 150)
        .cornerRadius(8)
    }
}

struct DarkBlueShadowProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ProgressView(configuration)
            .foregroundColor(.red)
            .foregroundStyle(.linearGradient(colors: [.pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
        LoadingView()
            .preferredColorScheme(.light)
    }
}
