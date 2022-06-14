//
//  TagListView.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/5/31.
//

import SwiftUI

struct TagListView: View {
    enum AlertType {
        case normal, confirm
    }
    
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    
    @State private var tagList: [String] = []
    @State private var selectedTag: String?
    
    @State private var alertType: AlertType = .normal
    @State private var showAlert = false
    @State private var alertMsg = ""
    
    @State private var showLoading = false
    @State private var showSelectRemoteView = false
    
    var body: some View {
        List {
            ForEach(tagList, id: \.self) { tag in
                HStack {
                    Text(tag)
                    Spacer()
                    if !store.remotes.isEmpty {
                        Button("删除") {
                            selectedTag = tag
                            showAlert = true
                            alertType = .confirm
                            alertMsg = "删除tag:`\(tag)`"
                        }
                    }
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
            alertView
        }
        .sheet(isPresented: $showLoading, onDismiss: {
            showLoading = false
        }, content: {
            LoadingView()
        })
        .sheet(isPresented: $showSelectRemoteView, onDismiss: {
            showSelectRemoteView = false
        }, content: {
            SelectRemoteView(confirmAction: {
                deleteTag()
            })
        })
        .onAppear {
            loadTagList()
        }
    }
    
    private var alertView: Alert {
        if alertType == .normal {
            return Alert(title: Text(alertMsg), message: nil, dismissButton: .default(Text("OK")))
        } else {
            return Alert(title: Text(alertMsg), message: nil, primaryButton: .destructive(Text("确认"), action: {
                deleteTag()
            }), secondaryButton: .default(Text("取消"), action: {
                showAlert = false
            }))
        }
    }
    
    private func deleteTag() {
        guard let tag = selectedTag else { return }
        guard let remote = store.remote else {
            showSelectRemoteView = true
            return
        }
        showLoading = true
        DispatchQueue.global().async {
            let error = Command.sharedInstance.deleteRemoteTag(tag, remote: remote)
            DispatchQueue.main.async {
                if error == nil {
                    debugPrint("删除远端tag:`\(tag)`成功")
                    deleteLocalTag(tag)
                } else {
                    showLoading = false
                    showAlert = true
                    alertType = .normal
                    alertMsg = "删除远端tag失败\n\(error!)"
                }
            }
        }
    }
    
    private func deleteLocalTag(_ tag: String) {
        showLoading = true
        DispatchQueue.global().async {
            let error = Command.sharedInstance.deleteLocalTag(tag)
            DispatchQueue.main.async {
                selectedTag = nil
                showLoading = false
                if error == nil {
                    debugPrint("删除本地tag:`\(tag)`成功")
                    loadTagList()
                } else {
                    showAlert = true
                    alertType = .normal
                    alertMsg = "删除本地tag失败\n\(error!)"
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
