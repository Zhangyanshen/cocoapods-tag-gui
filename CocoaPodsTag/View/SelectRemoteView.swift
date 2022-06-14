//
//  SelectRemoteView.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/6/14.
//

import SwiftUI

struct SelectRemoteView: View {
    var confirmAction: () -> Void = {}
    
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    
    @State private var remote: String?
    
    var body: some View {
        VStack {
            Text("选择remote")
                .font(.title3)
            Menu(remote ?? "") {
                ForEach(store.remotes, id: \.self) { r in
                    Button(r) {
                        remote = r
                    }
                }
            }
            .modifier(MenuStyle())
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("确认") {
                    confirm()
                }
                .disabled(remote == nil)
            }
        }
        .frame(minWidth: 300)
    }
    
    private func confirm() {
        store.remote = remote
        dismiss()
        confirmAction()
    }
}

struct SelectRemoteView_Previews: PreviewProvider {
    static var previews: some View {
        SelectRemoteView()
    }
}
