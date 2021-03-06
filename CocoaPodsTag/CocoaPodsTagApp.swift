//
//  CocoaPodsTagApp.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/4/20.
//

import SwiftUI

@main
struct CocoaPodsTagApp: App {
    @StateObject private var store = Store()
    @State private var pickerChoice: String = ""
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(after: CommandGroupPlacement.windowArrangement) {
                Picker("Appearance", selection: $pickerChoice) {
                    Text("Dark").tag("dark")
                    Text("Light").tag("light")
                    Text("System").tag("system")
                }
            }
        }
        
//        Settings {
//            
//        }
    }
}
