//
//  BlurView.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/4/21.
//

import SwiftUI

struct BlurView: NSViewRepresentable {
    func makeNSView(context: Context) -> some NSView {
        let blurView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        
        blurView.blendingMode = NSVisualEffectView.BlendingMode.behindWindow
        blurView.material = NSVisualEffectView.Material.hudWindow
        blurView.isEmphasized = true
        blurView.state = NSVisualEffectView.State.active
        
        return blurView;
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
}
