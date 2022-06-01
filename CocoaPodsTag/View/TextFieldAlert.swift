//
//  TextFieldAlert.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/4/21.
//

import SwiftUI

struct TextFieldAlert: View {
    var title = "请输入内容"
    var subTitle: String?
    var placeholder = "请输入内容"
    var firstButtonText = "取消"
    var secondButtonText = "确认"
    @Binding var text: String
    var okAction: ((String) -> Void)?
    var cancelAction: (() -> Void)?
    
    var body: some View {
        VStack {
            Text(title)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .font(.title3)
                .multilineTextAlignment(.center)
            if subTitle != nil {
                Text(subTitle!)
                    .foregroundColor(.secondary)
            }
            SecureField(placeholder, text: $text)
                .modifier(TextFieldStyle(bgColor: .primary))
                .border(Color("AlertBgColor").opacity(0.5), width: 0.5)
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
            HStack {
                Button(firstButtonText) {
                    guard let cancelAction = self.cancelAction else { return }
                    cancelAction()
                }
                .modifier(ButtonStyle(padding: 5, cornerRadius: 5))
                .padding(.trailing, 5)
                
                Button(secondButtonText) {
                    guard let okAction = self.okAction else { return }
                    okAction(text)
                }
                .modifier(ButtonStyle(padding: 5, cornerRadius: 5))
                .padding(.leading, 5)
            }
            .font(.title3)
            .padding(.vertical, 10)
        }
        .frame(width: 300, height: 200, alignment: .center)
        .cornerRadius(8)
    }
}

struct TextFieldAlert_Previews: PreviewProvider {
    static var previews: some View {
        TextFieldAlert(text: .constant(""))
        TextFieldAlert(text: .constant(""))
            .preferredColorScheme(.light)
    }
}
