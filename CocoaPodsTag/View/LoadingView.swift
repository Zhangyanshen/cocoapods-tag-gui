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
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .progressViewStyle(LinearProgressViewStyle())
            Text("请稍后...")
                .foregroundColor(.primary)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.bottom, 20)
        }
        .frame(width: 300)
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
        LoadingView()
            .preferredColorScheme(.light)
    }
}
