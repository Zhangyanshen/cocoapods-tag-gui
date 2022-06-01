//
//  TagListView.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/5/31.
//

import SwiftUI

struct TagListView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var tagList: [String]
    
    var body: some View {
        Table(tagList) {
            TableColumn("tag", value: \.self)
        }
        .frame(width: 300, height: 200)
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.cancellationAction) {
                Button("关闭") {
                    dismiss()
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
