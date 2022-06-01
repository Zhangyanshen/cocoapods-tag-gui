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
    private let matchVersion = "0.0.6"
    
    @Environment(\.colorScheme) var colorScheme

    @State private var log: NSAttributedString = NSAttributedString(string: "")
    @State private var running = false
    
    @State private var version: String = ""
    @State private var commitMsg: String = ""
    @State private var tagMsg: String = ""
    @State private var prefix: String = ""
    @State private var suffix: String = ""
    @State private var hasWorkDir: Bool = false
    @State private var workDir: String = "请先选择工作目录，工作目录必须包含podspec文件"
    
    @State private var remotes: [Substring] = []
    @State private var remote: String = ""
    
    @State private var specRepos: [SpecRepo] = []
    @State private var specRepo: String = ""
    
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
    
    // 执行命令的上下文
    var ctx: CustomContext {
        var cleanctx = CustomContext(main)
        if hasWorkDir && workDir.count != 0 {
            cleanctx.currentdirectory = workDir
        }
        cleanctx.env["LANG"] = "en_US.UTF-8"
        cleanctx.env["PATH"] = "\(main.env["HOME"]!)/.rvm/rubies/default/bin:\(main.env["HOME"]!)/.rvm/gems/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"
        return cleanctx
    }
    
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
            if !checkGemInstalled("cocoapods") {
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
            TagListView(tagList: $tagList)
        }
        .sheet(isPresented: $showSpecRepoView) {
            showSpecRepoView = false
        } content: {
            SpecRepoListView(specRepos: $specRepos) { specRepo in
                self.specRepo = specRepo
            }
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
            Text("\(workDir)")
            if hasWorkDir {
                Button("本地Tag") {
                    fetchTagList()
                }
                Button("从Finder中打开") {
                    openInFinder()
                }
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
            Menu(remote) {
                ForEach(remotes, id: \.self) { remote in
                    Button(remote) {
                        self.remote = String(remote)
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
            Text(specRepo)
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
            .disabled(running || specRepo == "")
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
            let result = ctx.run(bash: "git tag -l")
            DispatchQueue.main.async {
                if result.succeeded {
                    showTagList.toggle()
                    tagList = result.stdout.components(separatedBy: "\n").filter({$0 != ""})
                } else {
                    showAlert = true
                    alertMsg = "获取本地tag失败\n\(result.stderror)"
                }
            }
        }
    }
    
    private func openInFinder() {
        ctx.run(bash: "open \(workDir)")
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
    
    // 检查某个gem是否安装
    private func checkGemInstalled(_ name: String) -> Bool {
        let result = ctx.run(bash: "gem query \(name) -i")
        return result.succeeded
    }
    
    // 检查cocoapods-tag是否已经安装
    private func checkPlugin() {
        if checkGemInstalled("cocoapods-tag") {
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
            let result = ctx.run(bash: "gem query cocoapods-tag -i -v \(matchVersion)")
            if result.succeeded {
                generateAttributedString("cocoapods-tag已安装\n")
            } else {
                needUpdate = true
                running = true
                showPwdSheet = true
            }
        }
    }
    
    // 安装或更新cocoapods-tag
    private func installPlugin() {
        showLoading = true
        DispatchQueue.global().async {
            let tipStr = needUpdate ? "正在更新cocoapods-tag，请稍后...\n" : "正在安装cocoapods-tag，请稍后...\n"
            generateAttributedString(tipStr)
            
            let shellCommand = """
            echo "\(self.password)" | sudo -S gem install cocoapods-tag
            """
            
            let result = ctx.run(bash: shellCommand)
            debugPrint(result.exitcode)
            if result.succeeded {
                generateAttributedString(needUpdate ? "cocoapods-tag更新成功\n" : "cocoapods-tag安装成功\n")
                running = false
            } else {
                let msg = """
                \(needUpdate ? "cocoapods-tag更新失败" : "cocoapods-tag安装失败")
                
                \(result.stderror.regexReplace(with: outRegexPattern))
                请关闭并重新打开App再次尝试或者通过命令行手动操作`\(needUpdate ? "sudo gem update cocoapods-tag" : "sudo gem install cocoapods-tag")`
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
                    workDir = panel.url!.path
                    if workDir.count != 0 {
                        hasWorkDir = true
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
        if !hasWorkDir {
            return
        }
        DispatchQueue.global().async {
            if workDir.count != 0 {
                main.currentdirectory = workDir
            }
            let result = ctx.run("git", "remote")
            if result.succeeded {
                remotes = result.stdout.split(separator: "\n")
                if remotes.count == 1 {
                    remote = String(remotes[0])
                }
            } else {
                showAlert = true
                alertMsg = "选择的目录不包含.git文件夹，请重新选择"
                hasWorkDir = false
            }
        }
    }
    
    // 加载spec repos
    private func loadSpecRepos() {
        showLoading = true
        DispatchQueue.global().async {
            let result = ctx.run(bash: "pod tag repo-list --format=json")
            DispatchQueue.main.async {
                showLoading = false
                if result.succeeded {
                    showSpecRepoView = true
                    let repoListStr = result.stdout
                    let repoListJSON = JSON(parseJSON: repoListStr)
                    specRepos = repoListJSON.arrayValue.map { SpecRepo($0) }
                } else {
                    showAlert = true
                    alertMsg = "获取本地spec repo失败\n\(result.stderror)"
                }
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
        if remote.count != 0 {
            args.append("--remote=\(remote)")
        }
        if pushSpec && specRepo.count != 0 {
            args.append("--spec-repo=\(specRepo)")
        }
        if quick {
            args.append("--quick")
        }
        debugPrint(args)
        
        let command = ctx.runAsync("pod", args).onCompletion { command in
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
        if !hasWorkDir || workDir.strip().count == 0 {
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
        if remote.count == 0 {
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
