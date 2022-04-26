//
//  ContentView.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/4/20.
//

import SwiftUI
import SwiftShell

struct ContentView: View {
    private let versionRegex = "^([0-9]+(?>\\.[0-9a-zA-Z]+)*(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?)?$"

    @State private var log: String = ""
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
    
    @State private var specRepos: [String] = []
    @State private var specRepo: String = ""
    
    @State private var showAlert = false
    @State private var alertMsg = ""
    @State private var exit = false
    
    @State private var quick = false
    @State private var pushSpec = false
    
    @State private var password = ""
    @State private var showPwdSheet = false
    
    @State private var showLoading = false
    
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
            checkBoxView
            bottomButtonView
            CustomTextEditor(text: $log)
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
                loadGitRemotes()
                loadSpecRepos()
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
            TextFieldAlert(title: "安装插件需要管理员权限，请输入开机密码", placeholder: "请输入开机密码", firstButtonText: "退 出", secondButtonText: "确 认", text: $password) { password in
                self.password = password
                self.showPwdSheet = false
                installPlugin()
            } cancelAction: {
                self.showPwdSheet = false
                Darwin.exit(0)
            }
        })
        .sheet(isPresented: $showLoading) {
            LoadingView()
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
            
            Text("Remotes:")
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
            
            Text("Spec Repos:")
                .bold()
                .font(.title3)
            Menu(specRepo) {
                ForEach(specRepos, id: \.self) { repo in
                    Button(repo) {
                        self.specRepo = String(repo)
                    }
                }
            }
            .modifier(MenuStyle())
            .disabled(running)
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
                    log = ""
            })
        }
    }
    
    // MARK: - Private Methods
    
    // 检查某个gem是否安装
    private func checkGemInstalled(_ name: String) -> Bool {
        let gems = ctx.run("gem", "list").stdout.split(separator: "\n").filter { gem in
            gem.contains(name)
        }
        return gems.count > 0
    }
    
    // 检查cocoapods-tag是否已经安装
    private func checkPlugin() {
        if checkGemInstalled("cocoapods-tag") {
            log += "cocoapods-tag已安装\n"
        } else {
            running = true
            showPwdSheet = true
        }
    }
    
    // 安装cocoapods-tag
    private func installPlugin() {
        showLoading = true
        DispatchQueue.global().async {
            log += "正在安装cocoapods-tag，请稍后...\n"
            let shellCommand = "echo '\(self.password)' | sudo -S gem install cocoapods-tag"
            
            let result = ctx.run(bash: shellCommand)
            debugPrint(result.exitcode)
            if result.succeeded {
                log += "cocoapods-tag安装成功\n"
                running = false
            } else {
                let msg = """
                cocoapods-tag安装失败
                
                \(result.stderror)
                请关闭并重新打开App再次尝试安装或者通过命令行手动安装`sudo gem install cocoapods-tag`
                请确认密码输入正确
                """
                log += msg
                showAlert = true
                alertMsg = msg
            }
            DispatchQueue.main.async {
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
        DispatchQueue.global().async {
            specRepos = ctx.run("pod", "repo", "list").stdout.split(separator: "\n").filter({
                let valid = String($0) =~ "^-"
                return $0 != "" && !valid
            }).map({ String($0) })
            if specRepos.count > 0 {
                specRepos.removeLast()
            }
            if specRepos.count > 0 {
                specRepo = String(specRepos[0])
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
                alertMsg = "😭任务失败，请查看log😭"
            }
        }
        command.stdout.onStringOutput { str in
            DispatchQueue.main.async {
                log += "\(str)"
            }
        }
        command.stderror.onStringOutput { error in
            DispatchQueue.main.async {
                debugPrint(error)
                log += "\(error)"
            }
        }
    }
    
    // 参数检查
    private func check() -> Bool {
        if !hasWorkDir || workDir.strip().count == 0 {
            log += "请先选择工作目录！\n"
            alertMsg = "请先选择工作目录！"
            return false
        }
        if version.strip().count == 0 {
            log += "版本号不能为空！\n"
            alertMsg = "版本号不能为空！"
            return false
        }
        if !(version.strip() =~ versionRegex) {
            log += "版本号不符合规范！\n\(versionRegex)\n"
            alertMsg = "版本号不符合规范！\n\n\(versionRegex)"
            return false
        }
        if commitMsg.strip().count == 0 {
            log += "提交信息不能为空！\n"
            alertMsg = "提交信息不能为空！"
            return false
        }
        if remote.count == 0 {
            log += "请选择tag要推送到的remote！\n"
            alertMsg = "请选择tag要推送到的remote！"
            return false
        }
        if prefix.strip().count > 0 && prefix.strip().contains(" ") {
            log += "tag前缀不能包含空格！\n"
            alertMsg = "tag前缀不能包含空格！"
            return false
        }
        if suffix.strip().count > 0 && suffix.strip().contains(" ") {
            log += "tag后缀不能包含空格！\n"
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
