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
    
    var body: some View {
        VStack {
            Text("CocoaPods Tag")
                .font(.largeTitle)
                .foregroundColor(.primary)
                .padding()
            
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
                Menu("\(remote)") {
                    ForEach(remotes, id: \.self) { remote in
                        Button(remote) {
                            self.remote = String(remote)
                        }
                    }
                }
                .font(.title3)
                .disabled(running)
                
                Text("Spec Repos:")
                    .bold()
                    .font(.title3)
                Menu("\(specRepo)") {
                    ForEach(specRepos, id: \.self) { repo in
                        Button(repo) {
                            self.specRepo = String(repo)
                        }
                    }
                }
                .font(.title3)
                .disabled(running)
            }
            .padding(8)
            
            // 复选框
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
            
            // 底部按钮
            HStack {
                CustomButton(
                    title: "创建Tag",
                    running: running,
                    action: {
                        createTag()
                })
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text(alertMsg), dismissButton: .default(Text("OK"), action: {
                            if exit {
                                Darwin.exit(0)
                            }
                        }))
                    }
                CustomButton(
                    title: "清空日志",
                    running: running,
                    action: {
                        log = ""
                })
            }
            
            CustomTextEditor(text: $log)
        }
        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.5), Color.blue.opacity(0.5)]), startPoint: .leading, endPoint: .trailing)
        )
        .ignoresSafeArea()
        .onAppear {
            installPlugin()
            loadGitRemotes()
            loadSpecRepos()
            if !checkGemInstalled("cocoapods") {
                showAlert = true
                alertMsg = "您还未安装CocoaPods，请先安装CocoaPods！"
                exit = true
            }
        }
    }
    
    // 检查某个gem是否安装
    private func checkGemInstalled(_ name: String) -> Bool {
        let gems = run("gem", "list").stdout.split(separator: "\n").filter { gem in
            gem.contains(name)
        }
        return gems.count > 0
    }
    
    // 判断cocoapods-tag是否安装
    private func installPlugin() {
        DispatchQueue.global().async {
            configENV()
            if !checkGemInstalled("cocoapods-tag") {
                running = true
                log += "正在安装cocoapods-tag，请稍后...\n"
                let _ = run("gem", "install", "cocoapods-tag")
                if checkGemInstalled("cocoapods-tag") {
                    log += "cocoapods-tag安装成功\n"
                    running = false
                } else {
                    log += "cocoapods-tag安装失败，请关闭并重新打开App再次尝试安装\n"
                }
            } else {
                log += "cocoapods-tag已安装\n"
            }
        }
    }
    
    // 选择工作目录
    private func selectWorkDir() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        let response = panel.runModal()
        if response == .OK {
            workDir = panel.url?.path ?? ""
            if workDir.count != 0 {
                hasWorkDir = true
                loadGitRemotes()
            }
        }
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
            let result = run("git", "remote")
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
            configENV()
            specRepos = run("pod", "repo", "list").stdout.split(separator: "\n").filter({
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
    
    // 配置环境变量
    private func configENV() {
        if hasWorkDir && workDir.count != 0 {
            main.currentdirectory = workDir
        }
        main.env["LANG"] = "en_US.UTF-8"
        main.env["PATH"] = "\(main.env["HOME"]!)/.rvm/rubies/default/bin:\(main.env["HOME"]!)/.rvm/gems/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"
    }

    // 创建tag
    private func createTag() {
        if !check() {
            showAlert = true
            return
        }
        running = true
        configENV()
        
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
        print(args)
//        running = false
//        return
        
        let command = main.runAsync("pod", args).onCompletion { command in
            running = false
            showAlert = true
            if command.exitcode() == 0 {
                alertMsg = "😄恭喜你完成任务😄"
            } else {
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
        if !(version.strip() =~ versionRegex) {
            log += "版本号不符合规范！\n\(versionRegex)\n"
            alertMsg = "版本号不符合规范！\n\n\(versionRegex)"
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
        .padding(10)
        .background(
            ZStack {
                Color.blue
                LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]), startPoint: .top, endPoint: .bottom)
            }
        )
        .foregroundColor(.white)
        .cornerRadius(10)
        .buttonStyle(.plain)
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
                .font(.title3)
                .disabled(disabled)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        ContentView()
            .preferredColorScheme(.dark)
    }
}
