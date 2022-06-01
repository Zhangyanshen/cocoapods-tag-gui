//
//  SpecRepoListView.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/6/1.
//

import SwiftUI

struct SpecRepoListView: View {
    var specRepos: [SpecRepo] = []
    var confirmAction: (String) -> Void = { _ in }
    @Environment(\.dismiss) var dismiss
    @State private var selectedSpecRepo: SpecRepo.ID?
    
    var body: some View {
        Table(specRepos, selection: $selectedSpecRepo) {
            TableColumn("name", value: \.name)
            TableColumn("url", value: \.url)
        }
        .frame(minWidth: 700, minHeight: 400)
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.cancellationAction) {
                Button("关闭") {
                    dismiss()
                }
            }
            ToolbarItem(placement: ToolbarItemPlacement.confirmationAction) {
                Button("确认") {
                    confirmSelect()
                }
                .disabled(selectedSpecRepo == nil)
            }
        }
    }
    
    private func confirmSelect() {
        let selectedRepos = specRepos.filter({ $0.id == selectedSpecRepo })
        if selectedRepos.count > 0 {
            confirmAction(selectedRepos.first!.name)
            dismiss()
        }
    }
}

struct SpecRepoListView_Previews: PreviewProvider {
    static var previews: some View {
        SpecRepoListView()
    }
}
