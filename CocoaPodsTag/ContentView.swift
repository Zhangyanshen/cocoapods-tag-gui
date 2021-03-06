//
//  ContentView.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/4/20.
//

import SwiftUI
import SwiftShell
import SwiftyJSON

struct ContentView: View {
    private let versionRegex = "^([0-9]+(?>\\.[0-9a-zA-Z]+)*(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?)?$"
    private let outRegexPattern = "\\[[0-9]+m"
    
    @EnvironmentObject var store: Store
    @Environment(\.colorScheme) var colorScheme

    @State private var log: NSAttributedString = NSAttributedString(string: "")
    @State private var running = false
    
    @State private var version: String = ""
    @State private var commitMsg: String = ""
    @State private var tagMsg: String = ""
    @State private var prefix: String = ""
    @State private var suffix: String = ""
    
    @State private var showAlert = false
    @State private var alertMsg = ""
    @State private var exit = false
    
    @State private var needUpdate = false
    
    @State private var quick = false
    @State private var pushSpec = false
    
    @State private var password = ""
    @State private var showPwdSheet = false
    
    @State private var showLoading = false
    
    @State private var showTagList = false
    @State private var tagList: [String] = []
    
    @State private var showSpecRepoView = false
        
    // MARK: - Body
    
    var body: some View {
        VStack {
            titleView
            workDirView
            firstRowView
            secondRowView
            thirdRowView
            checkBoxView
            bottomButtonView
            CustomTextView(richString: log)
                .padding()
        }
        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        .background(BlurView())
        .ignoresSafeArea()
        .onAppear {
            
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertMsg), dismissButton: .default(Text("OK"), action: {
                if exit {
                    Darwin.exit(0)
                }
            }))
        }
        .sheet(isPresented: $showLoading) {
            LoadingView()
        }
        .sheet(isPresented: $showTagList) {
            showTagList = false
        } content: {
            TagListView()
        }
        .sheet(isPresented: $showSpecRepoView) {
            showSpecRepoView = false
        } content: {
            SpecRepoListView()
        }
    }
    
    // ??????
    var titleView: some View {
        Text("CocoaPods Tag")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(
                .linearGradient(colors: [.pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .padding()
    }
    
    // ????????????
    var workDirView: some View {
        HStack {
            CustomButton(
                title: "??????????????????",
                running: running,
                action: {
                    selectWorkDir()
            })
            if Command.sharedInstance.hasWorkDir {
                Text(Command.sharedInstance.workDir!)
                Button("??????Tag") {
                    fetchTagList()
                }
                Button("???Finder?????????") {
                    openInFinder()
                }
            } else {
                Text("???????????????????????????????????????????????????podspec??????")
            }
            Spacer()
        }
        .padding(8)
    }
    
    var firstRowView: some View {
        HStack {
            CustomTextField(
                tip: "?????????:",
                placeholder: "??????????????????",
                content: $version,
                disabled: $running
            )
            CustomTextField(
                tip: "????????????:",
                placeholder: "?????????????????????",
                content: $commitMsg,
                disabled: $running
            )
            CustomTextField(
                tip: "tag??????:",
                placeholder: "?????????tag??????(??????)",
                content: $tagMsg,
                disabled: $running
            )
        }
        .padding(8)
    }
    
    var secondRowView: some View {
        HStack {
            CustomTextField(
                tip: "??????:",
                placeholder: "???????????????(??????)",
                content: $prefix,
                disabled: $running)
            CustomTextField(
                tip: "??????:",
                placeholder: "???????????????(??????)",
                content: $suffix,
                disabled: $running
            )
            
            Text("Remote:")
                .bold()
                .font(.title3)
            Menu(store.remote ?? "") {
                ForEach(store.remotes, id: \.self) { remote in
                    Button(remote) {
                        store.remote = String(remote)
                    }
                }
            }
            .disabled(running)
            .modifier(MenuStyle())
        }
        .padding(8)
    }
    
    var thirdRowView: some View {
        HStack {
            Button("??????spec repo") {
                loadSpecRepos()
            }
            .disabled(running)
            Text(store.selectedSpecRepo)
            Spacer()
        }
        .padding(8)
    }
    
    // ?????????
    var checkBoxView: some View {
        HStack {
            Toggle(isOn: $quick) {
                Text("??????????????????")
            }
            Toggle(isOn: $pushSpec) {
                Text("??????podspec")
            }
            .disabled(running)
        }
        .disabled(running)
        .padding(8)
    }
    
    // ????????????
    var bottomButtonView: some View {
        HStack {
            CustomButton(
                title: "??????Tag",
                running: running,
                action: {
                    createTag()
            })
            CustomButton(
                title: "????????????",
                running: running,
                action: {
                    log = NSAttributedString(string: "")
            })
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchTagList() {
        DispatchQueue.global().async {
            let (tags, error) = Command.sharedInstance.fetchTagList()
            DispatchQueue.main.async {
                if error == nil {
                    showTagList.toggle()
                    tagList = tags
                } else {
                    showAlert = true
                    alertMsg = "????????????tag??????\n\(error!)"
                }
            }
        }
    }
    
    private func openInFinder() {
        Command.sharedInstance.openInFinder()
    }
    
    // ??????AttributedString
    private func generateAttributedString(_ text: String, isError: Bool = false) {
        let attrStr = NSMutableAttributedString(attributedString: log)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 5;
        let addAttrs = [
            NSAttributedString.Key.foregroundColor: isError ? NSColor.systemRed : colorScheme == .dark ? NSColor.white : NSColor.black,
            NSAttributedString.Key.font: isError ? NSFont.boldSystemFont(ofSize: 15) : NSFont.systemFont(ofSize: 15),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]
        let appendAttr = NSAttributedString(string: text, attributes: addAttrs)
        attrStr.append(appendAttr)
        log = attrStr
    }
    
    // ??????????????????
    private func selectWorkDir() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow()) { response in
            if response == .OK {
                if checkWorkDir(panel.url) {
                    Command.sharedInstance.workDir = panel.url?.path
                    if Command.sharedInstance.workDir != nil {
                        loadGitRemotes()
                    }
                }
            }
        }
    }
    
    // ??????????????????
    private func checkWorkDir(_ workDirURL: URL?) -> Bool {
        if workDirURL == nil {
            showAlert = true
            alertMsg = "?????????????????????nil??????????????????"
            return false
        }
        let gitRepoDir = "\(workDirURL!.path)/.git"
        if !FileManager.default.fileExists(atPath: gitRepoDir) {
            showAlert = true
            alertMsg = "?????????????????????.git???????????????????????????"
            return false
        }
        return true
    }
    
    // ??????git
    private func loadGitRemotes() {
        store.remote = nil
        DispatchQueue.global().async {
            let (remotes, error) = Command.sharedInstance.loadGitRemotes()
            DispatchQueue.main.async {
                if error == nil {
                    store.remotes = remotes
                    if remotes.count == 1 {
                        store.remote = remotes[0]
                    }
                } else {
                    showAlert = true
                    alertMsg = "??????remote??????\n\(error!)"
                }
            }
        }
    }
    
    // ??????spec repos
    private func loadSpecRepos() {
        showLoading = true
        DispatchQueue.global().async {
            let (repos, error) = Command.sharedInstance.loadSpecRepos()
            DispatchQueue.main.async {
                showLoading = false
                if error == nil {
                    showSpecRepoView = true
                    store.specRepos = repos
                } else {
                    showAlert = true
                    alertMsg = "????????????spec repo??????\n\(error!)"
                }
            }
        }
    }
    
    private func removeInvalidSpecRepo() {
        showLoading = true
        DispatchQueue.global().async {
            let validSpecRepos = store.removeInvalidSpecRepos()
            DispatchQueue.main.async {
                store.specRepos = validSpecRepos
                store.save()
                showLoading = false
                showSpecRepoView = true
            }
        }
    }

    // ??????tag
    private func createTag() {
        if !check() {
            showAlert = true
            return
        }
        running = true
        showLoading = true
        
        var args = ["tag", version.strip(), commitMsg]
        if tagMsg.strip().count != 0 {
            args.append(tagMsg)
        }
        if prefix.strip().count != 0 {
            args.append("--prefix=\(prefix.strip())")
        }
        if suffix.strip().count != 0 {
            args.append("--suffix=\(suffix.strip())")
        }
        if store.remote != nil {
            args.append("--remote=\(store.remote!)")
        }
        if pushSpec {
            args.append("--spec-repo=\(store.selectedSpecRepo)")
        }
        if quick {
            args.append("--quick")
        }
        debugPrint(args)
        
        let command = Command.sharedInstance.ctx.runAsync("pod", args).onCompletion { command in
            running = false
            showLoading = false
            showAlert = true
            if command.exitcode() == 0 {
                alertMsg = "?????????????????????????????"
            } else {
                debugPrint(command.exitcode())
                alertMsg = "????????????????????????????log????\n\(command.stderror)"
            }
        }
        command.stdout.onStringOutput { str in
            DispatchQueue.main.async {
                generateAttributedString("\(str)\n", isError: str.contains("[!]"))
            }
        }
        command.stderror.onStringOutput { error in
            DispatchQueue.main.async {
                debugPrint(error)
                generateAttributedString("\(error.regexReplace(with: outRegexPattern))\n", isError: true)
            }
        }
    }
    
    // ????????????
    private func check() -> Bool {
        if Command.sharedInstance.workDir == nil {
            generateAttributedString("???????????????????????????\n")
            alertMsg = "???????????????????????????"
            return false
        }
        if version.strip().count == 0 {
            generateAttributedString("????????????????????????\n")
            alertMsg = "????????????????????????"
            return false
        }
        if !(version.strip() =~ versionRegex) {
            generateAttributedString("???????????????????????????\n\(versionRegex)\n")
            alertMsg = "???????????????????????????\n\n\(versionRegex)"
            return false
        }
        if commitMsg.strip().count == 0 {
            generateAttributedString("???????????????????????????\n")
            alertMsg = "???????????????????????????"
            return false
        }
        if store.remote == nil {
            generateAttributedString("?????????tag???????????????remote???\n")
            alertMsg = "?????????tag???????????????remote???"
            return false
        }
        if prefix.strip().count > 0 && prefix.strip().contains(" ") {
            generateAttributedString("tag???????????????????????????\n")
            alertMsg = "tag???????????????????????????"
            return false
        }
        if suffix.strip().count > 0 && suffix.strip().contains(" ") {
            generateAttributedString("tag???????????????????????????\n")
            alertMsg = "tag???????????????????????????"
            return false
        }
        return true
    }
}

// MARK: - Custom View

struct CustomButton: View {
    var title: String
    var running: Bool
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.title3)
                .bold()
        }
        .disabled(running)
        .modifier(ButtonStyle())
    }
}

struct CustomTextField: View {
    var tip: String
    var placeholder: String
    @Binding var content: String
    @Binding var disabled: Bool
    
    var body: some View {
        Group {
            Text("\(tip)")
                .font(.title3)
            TextField("\(placeholder)", text: $content)
                .disabled(disabled)
                .modifier(TextFieldStyle())
        }
    }
}

struct CustomTextEditor: View {
    @Binding var text: String
    
    var body: some View {
        TextEditor(text: .constant(self.text))
            .font(.title3)
            .background(Color.clear)
            .padding()
            .lineSpacing(8)
            .font(.title3)
    }
}

// MARK: - Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        ContentView()
            .preferredColorScheme(.light)
    }
}
