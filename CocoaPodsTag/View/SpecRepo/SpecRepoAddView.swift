//
//  SpecRepoAddView.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/6/7.
//

import SwiftUI

struct SpecRepoAddView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var url = ""
    @State private var branch: String?
    @State private var branches: [String] = []
    
    @State private var showLoading = false
    @State private var showAlert = false
    @State private var alertMsg = ""
    
    var body: some View {
        VStack {
            HStack {
                Text("name:")
                TextField("请输入名称", text: $name)
            }
            HStack {
                Text("url:")
                TextField("请输入URL", text: $url)
            }
            HStack {
                Text("branch:")
                Menu(branch ?? "选择分支") {
                    ForEach(branches, id: \.self) { br in
                        Button(br) {
                            branch = br
                        }
                    }
                }
                Button("刷新") {
                    fetchRemoteBranches()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("确认") {
                    addSpecRepo()
                }
            }
        }
        .sheet(isPresented: $showLoading, onDismiss: {
            showLoading = false
        }, content: {
            LoadingView()
        })
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text(alertMsg), message: nil, dismissButton: .default(Text("OK")))
        })
        .onChange(of: url, perform: { _ in
            branch = nil
            branches = []
        })
        .padding()
        .frame(minWidth: 400)
    }
    
    private func fetchRemoteBranches() {
        if url.strip().count == 0 {
            showAlert = true
            alertMsg = "url不能为空"
            return
        }
        showLoading = true
        DispatchQueue.global().async {
            let (branches, error) = Command.sharedInstance.gitRemoteBranches(of: url.strip())
            DispatchQueue.main.async {
                showLoading = false
                if error == nil {
                    self.branches = branches
                    branch = branches[0]
                } else {
                    showAlert = true
                    alertMsg = "获取远端分支失败\n\(error!)"
                }
            }
        }
    }
    
    private func addSpecRepo() {
        if name.strip().count == 0 {
            showAlert = true
            alertMsg = "name不能为空"
            return
        }
        if url.strip().count == 0 {
            showAlert = true
            alertMsg = "url不能为空"
            return
        }
        guard let branch = branch else {
            showAlert = true
            alertMsg = "请选择分支"
            return
        }
        
        showLoading = true
        DispatchQueue.global().async {
            let error = Command.sharedInstance.addSpecRepo(name, url: url, branch: branch)
            DispatchQueue.main.async {
                showLoading = false
                if error == nil {
                    let dic = [
                        "name": name,
                        "url": url
                    ]
                    let spec = SpecRepo(dic)
                    store.specRepos.append(spec)
                    dismiss()
                } else {
                    showAlert = true
                    alertMsg = "添加spec repo失败\n\(error!)"
                }
            }
        }
    }
    
//    private func removeExistSpecRepo() {
//        Command.sharedInstance.removeSpecRepo(name)
//    }
}

struct SpecRepoAddView_Previews: PreviewProvider {
    static var previews: some View {
        SpecRepoAddView()
    }
}
