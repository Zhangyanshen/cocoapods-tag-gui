//
//  TagListView.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/5/31.
//

import SwiftUI

struct TagListView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var tagList: [String] = []
    @State private var showAlert = false
    @State private var alertMsg = ""
    @State private var selectedTag: String?
    
    @State private var showLoading = false
    
    var body: some View {
        List {
            ForEach(tagList, id: \.self) { tag in
                HStack {
                    Text(tag)
                    Spacer()
//                    Button("删除") {
//                        selectedTag = tag
//                        showAlert = true
//                        alertMsg = "删除tag:`\(tag)`"
//                    }
                }
            }
        }
        .frame(width: 300, height: 200)
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.cancellationAction) {
                Button("关闭") {
                    dismiss()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertMsg), message: nil, primaryButton: .destructive(Text("确认"), action: {
                deleteTag()
            }), secondaryButton: .default(Text("取消"), action: {
                showAlert = false
            }))
        }
        .sheet(isPresented: $showLoading, onDismiss: {
            showLoading = false
        }, content: {
            LoadingView()
        })
        .onAppear {
            loadTagList()
        }
    }
    
    private func deleteTag() {
        guard let tag = selectedTag else { return }
        showLoading = true
        DispatchQueue.global().async {
            let error = Command.sharedInstance.deleteLocalTag(tag)
            DispatchQueue.main.async {
                if error == nil {
                    deleteRemoteTag()
                } else {
                    showAlert = true
                    alertMsg = "删除本地tag失败\n\(error!)"
                }
            }
        }
    }
    
    private func deleteRemoteTag() {
        guard let tag = selectedTag else { return }
        showLoading = true
        DispatchQueue.global().async {
            let error = Command.sharedInstance.deleteRemoteTag(tag, remote: "origin")
            DispatchQueue.main.async {
                selectedTag = nil
                showLoading = false
                if error == nil {
                    loadTagList()
                } else {
                    showAlert = true
                    alertMsg = "删除远程tag失败\n\(error!)"
                }
            }
        }
    }
    
    private func loadTagList() {
        DispatchQueue.global().async {
            let (tags, error) = Command.sharedInstance.fetchTagList()
            DispatchQueue.main.async {
                if error == nil {
                    tagList = tags
                } else {
                    showAlert = true
                    alertMsg = "加载本地tag失败\n\(error!)"
                }
            }
        }
    }
}

//struct TagListView_Previews: PreviewProvider {
//    static var previews: some View {
//        TagListView(tagList: ["0.0.1", "0.0.2"])
//    }
//}
