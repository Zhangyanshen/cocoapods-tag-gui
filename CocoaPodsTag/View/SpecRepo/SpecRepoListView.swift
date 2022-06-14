//
//  SpecRepoListView.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/6/1.
//

import SwiftUI

struct SpecRepoListView: View {
    enum AlertType {
        case normal, confirm
    }
    
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedSpecRepo: SpecRepo.ID?
    @State private var showSpecRepoAddView = false
    @State private var showLoading = false
    @State private var showAlert = false
    @State private var alertMsg = ""
    @State private var alertType = AlertType.normal
    
    var body: some View {
        Group {
            Table(store.specRepos, selection: $selectedSpecRepo) {
                TableColumn("name", value: \.name)
                TableColumn("url", value: \.url)
            }
        }
        .frame(minWidth: 700, minHeight: 400)
        .sheet(isPresented: $showSpecRepoAddView, onDismiss: {
            showSpecRepoAddView = false
        }, content: {
            SpecRepoAddView()
        })
        .sheet(isPresented: $showLoading, onDismiss: {
            showLoading = false
        }, content: {
            LoadingView()
        })
        .alert(isPresented: $showAlert, content: {
            alertView
        })
        .toolbar {
            ToolbarItem {
                Button {
                    showSpecRepoAddView = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button {
                    showAlert = true
                    if selectedSpecRepo == nil {
                        alertType = .normal
                        alertMsg = "请选择要删除的spec repo"
                        return
                    }
                    alertType = .confirm
                    alertMsg = "确认删除该spec repo吗？"
                } label: {
                    Image(systemName: "trash")
                }
            }
//            ToolbarItemGroup {
//                Text("\(store.specRepos.count) repos")
//            }
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("确认") {
                    confirmSelect()
                }
                .disabled(selectedSpecRepo == nil)
            }
        }
    }
    
    private var alertView: Alert {
        if alertType == .normal {
            return Alert(title: Text(alertMsg), message: nil, dismissButton: .default(Text("OK")))
        } else {
            return Alert(title: Text(alertMsg), message: nil, primaryButton: .destructive(Text("确认"), action: {
                deleteSpecRepo()
            }), secondaryButton: .default(Text("取消"), action: {
                showAlert = false
            }))
        }
    }
    
    private func deleteSpecRepo() {
        showLoading = true
        DispatchQueue.global().async {
            let selectedRepos = store.specRepos.filter({ $0.id == selectedSpecRepo })
            let error = Command.sharedInstance.removeSpecRepo(selectedRepos[0].name)
            DispatchQueue.main.async {
                showLoading = false
                if error == nil {
                    store.specRepos.removeAll { repo in
                        repo.id == selectedSpecRepo
                    }
                    selectedSpecRepo = nil
                } else {
                    showAlert = true
                    alertType = .normal
                    alertMsg = "删除本地spec repo失败\n\(error!)"
                }
            }
        }
    }
    
    private func confirmSelect() {
        let selectedRepos = store.specRepos.filter({ $0.id == selectedSpecRepo })
        if selectedRepos.count > 0 {
            store.selectedSpecRepo = selectedRepos[0].url
            dismiss()
        }
    }
}

struct SpecRepoListView_Previews: PreviewProvider {
    static var previews: some View {
        SpecRepoListView()
    }
}
