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
    private let matchVersion = "0.0.7"
    
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
            if !Command.sharedInstance.checkGemInstalled("cocoapods") {
                showAlert = true
                alertMsg = "您还未安装CocoaPods，请先安装CocoaPods！"
                exit = true
            } else {
                checkPlugin()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertMsg), dismissButton: .default(Text("OK"), action: {
                if exit {
                    Darwin.exit(0)
                }
            }))
        }
        .sheet(isPresented: $showPwdSheet, content: {
            TextFieldAlert(title: needUpdate ? "更新插件到v\(matchVersion)" : "安装插件", subTitle: "安装插件需要管理员权限，请输入开机密码", placeholder: "请输入开机密码", firstButtonText: "退 出", secondButtonText: "确 认", text: $password) { password in
                self.password = password
                self.showPwdSheet = false
                installPlugin()
            } cancelAction: {
                self.showPwdSheet = false
                self.needUpdate = false
                Darwin.exit(0)
            }
        })
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
    
    // 标题
    var titleView: some View {
        Text("CocoaPods Tag")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(
                .linearGradient(colors: [.pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .padding()
    }
    
    // 工作目录
    var workDirView: some View {
        HStack {
            CustomButton(
                title: "选择工作目录",
                running: running,
                action: {
                    selectWorkDir()
            })
            if Command.sharedInstance.hasWorkDir {
                Text(Command.sharedInstance.workDir!)
                Button("本地Tag") {
                    fetchTagList()
                }
                Button("从Finder中打开") {
                    openInFinder()
                }
            } else {
                Text("请先选择工作目录，工作目录必须包含podspec文件")
            }
            Spacer()
        }
        .padding(8)
    }
    
    var firstRowView: some View {
        HStack {
            CustomTextField(
                tip: "版本号:",
                placeholder: "请输入版本号",
                content: $version,
                disabled: $running
            )
            CustomTextField(
                tip: "提交信息:",
                placeholder: "请输入提交信息",
                content: $commitMsg,
                disabled: $running
            )
            CustomTextField(
                tip: "tag信息:",
                placeholder: "请输入tag信息(可选)",
                content: $tagMsg,
                disabled: $running
            )
        }
        .padding(8)
    }
    
    var secondRowView: some View {
        HStack {
            CustomTextField(
                tip: "前缀:",
                placeholder: "请输入前缀(可选)",
                content: $prefix,
                disabled: $running)
            CustomTextField(
                tip: "后缀:",
                placeholder: "请输入后缀(可选)",
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
            Button("选择spec repo") {
                loadSpecRepos()
            }
            .disabled(running)
            Text(store.selectedSpecRepo)
            Spacer()
        }
        .padding(8)
    }
    
    // 复选框
    var checkBoxView: some View {
        HStack {
            Toggle(isOn: $quick) {
                Text("跳过耗时验证")
            }
            Toggle(isOn: $pushSpec) {
                Text("推送podspec")
            }
            .disabled(running)
        }
        .disabled(running)
        .padding(8)
    }
    
    // 底部按钮
    var bottomButtonView: some View {
        HStack {
            CustomButton(
                title: "创建Tag",
                running: running,
                action: {
                    createTag()
            })
            CustomButton(
                title: "清空日志",
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
                    alertMsg = "获取本地tag失败\n\(error!)"
                }
            }
        }
    }
    
    private func openInFinder() {
        Command.sharedInstance.openInFinder()
    }
    
    // 生成AttributedString
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
    
    // 检查cocoapods-tag是否已经安装
    private func checkPlugin() {
        if Command.sharedInstance.checkGemInstalled("cocoapods-tag") {
            checkPluginVersion()
        } else {
            needUpdate = false
            running = true
            showPwdSheet = true
        }
    }
    
    // 检查cocoapods-tag版本号
    private func checkPluginVersion() {
        DispatchQueue.global().async {
            let installed = Command.sharedInstance.checkPluginVersion(for: "cocoapods-tag", version: matchVersion)
            DispatchQueue.main.async {
                if installed {
                    generateAttributedString("cocoapods-tag已安装\n")
                } else {
                    needUpdate = true
                    running = true
                    showPwdSheet = true
                }
            }
        }
    }
    
    // 安装或更新cocoapods-tag
    private func installPlugin() {
        showLoading = true
        DispatchQueue.global().async {
            let tipStr = "正在\(needUpdate ? "更新" : "安装")cocoapods-tag，请稍后...\n"
            generateAttributedString(tipStr)
            
            Command.sharedInstance.uninstallGem("cocoapods-tag", password: password)
            let error = Command.sharedInstance.installGem("cocoapods-tag", password: password)
            
            if error == nil {
                generateAttributedString("cocoapods-tag\(needUpdate ? "更新" : "安装")成功\n")
                running = false
            } else {
                let msg = """
                "cocoapods-tag\(needUpdate ? "更新" : "安装")失败"
                
                \(error!)
                请关闭并重新打开App再次尝试或者通过命令行手动安装`sudo gem install cocoapods-tag`
                请确认密码输入正确
                """
                generateAttributedString(msg, isError: true)
                showAlert = true
                alertMsg = msg
            }
            DispatchQueue.main.async {
                needUpdate = false
                showLoading = false
            }
        }
    }
    
    // 选择工作目录
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
    
    // 检查工作目录
    private func checkWorkDir(_ workDirURL: URL?) -> Bool {
        if workDirURL == nil {
            showAlert = true
            alertMsg = "工作目录不能为nil，请重新选择"
            return false
        }
        let gitRepoDir = "\(workDirURL!.path)/.git"
        if !FileManager.default.fileExists(atPath: gitRepoDir) {
            showAlert = true
            alertMsg = "工作目录不包含.git文件夹，请重新选择"
            return false
        }
        return true
    }
    
    // 获取git
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
                    alertMsg = "获取remote失败\n\(error!)"
                }
            }
        }
    }
    
    // 加载spec repos
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
                    alertMsg = "获取本地spec repo失败\n\(error!)"
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

    // 创建tag
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
                alertMsg = "😄恭喜你完成任务😄"
            } else {
                debugPrint(command.exitcode())
                alertMsg = "😭任务失败，请查看log😭\n\(command.stderror)"
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
    
    // 参数检查
    private func check() -> Bool {
        if Command.sharedInstance.workDir == nil {
            generateAttributedString("请先选择工作目录！\n")
            alertMsg = "请先选择工作目录！"
            return false
        }
        if version.strip().count == 0 {
            generateAttributedString("版本号不能为空！\n")
            alertMsg = "版本号不能为空！"
            return false
        }
        if !(version.strip() =~ versionRegex) {
            generateAttributedString("版本号不符合规范！\n\(versionRegex)\n")
            alertMsg = "版本号不符合规范！\n\n\(versionRegex)"
            return false
        }
        if commitMsg.strip().count == 0 {
            generateAttributedString("提交信息不能为空！\n")
            alertMsg = "提交信息不能为空！"
            return false
        }
        if store.remote == nil {
            generateAttributedString("请选择tag要推送到的remote！\n")
            alertMsg = "请选择tag要推送到的remote！"
            return false
        }
        if prefix.strip().count > 0 && prefix.strip().contains(" ") {
            generateAttributedString("tag前缀不能包含空格！\n")
            alertMsg = "tag前缀不能包含空格！"
            return false
        }
        if suffix.strip().count > 0 && suffix.strip().contains(" ") {
            generateAttributedString("tag后缀不能包含空格！\n")
            alertMsg = "tag后缀不能包含空格！"
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
