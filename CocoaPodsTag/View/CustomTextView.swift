//
//  CustomTextView.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/5/31.
//

import SwiftUI

struct CustomTextView: NSViewRepresentable {
    @Environment(\.colorScheme) var colorScheme
    
    typealias NSViewType = NSScrollView

    var richString: NSAttributedString?
    let isSelectable: Bool = false
    var insetSize: CGSize = .zero
    
    func makeNSView(context: Context) -> NSViewType {
        let scrollView = NSTextView.scrollableTextView()

        let textView = scrollView.documentView as! NSTextView
        textView.textColor = .controlTextColor
        textView.textContainerInset = insetSize
        textView.backgroundColor = .white
        
        return scrollView
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        let textView = (nsView.documentView as! NSTextView)
        textView.isSelectable = isSelectable
        textView.backgroundColor = colorScheme == .dark ? NSColor.black : NSColor.white

        if let attributedText = richString, attributedText != textView.attributedString() {
            textView.textStorage?.setAttributedString(attributedText)
        }

        if let lineLimit = context.environment.lineLimit {
            textView.textContainer?.maximumNumberOfLines = lineLimit
        }
        // 滚动到底部
        textView.scrollToEndOfDocument(nil)
    }
}
