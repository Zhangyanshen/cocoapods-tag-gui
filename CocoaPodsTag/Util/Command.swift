//
//  Command.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/6/7.
//

import Foundation
import SwiftShell
import SwiftyJSON

class Command {
    static let sharedInstance = Command()
    
    private let outRegexPattern = "\\[[0-9]+m"
    
    var workDir: String?
    
    var hasWorkDir: Bool {
        return workDir != nil
    }
    
    // 执行命令的上下文
    var ctx: CustomContext {
        var cleanctx = CustomContext(main)
        if workDir != nil {
            cleanctx.currentdirectory = workDir!
        }
        cleanctx.env["LANG"] = "en_US.UTF-8"
        var env: String = ""
        if let resourcesDir = Bundle.main.resourcePath {
            env = "\(resourcesDir)/bundle/ruby/2.7.0/bin:/usr/bin:"
        }
        cleanctx.env["PATH"] = env
        return cleanctx
    }
    
    init() {}
    
    // MARK: - Public methods
    
    // MARK: git
    
    func gitRemoteBranches(of url: String) -> ([String], String?) {
        let result = ctx.run(bash: "git ls-remote --heads --quiet \(url)")
        if result.succeeded {
            let branches = result.stdout.components(separatedBy: "\n").map { str in
                guard let lastStr = str.components(separatedBy: "\t").last else { return "" }
                return lastStr.replacingOccurrences(of: "refs/heads/", with: "")
            }.filter({
                $0 != ""
            })
            return (branches, nil)
        } else {
            return ([], formatErrorMsg(result.stderror))
        }
    }
    
    func loadGitRemotes() -> ([String], String?) {
        let result = ctx.run("git", "remote")
        if result.succeeded {
            let remotes = result.stdout.components(separatedBy: "\n").filter({$0 != ""})
            return (remotes, nil)
        } else {
            return ([], formatErrorMsg(result.stderror))
        }
    }
    
    func fetchTagList() -> ([String], String?) {
        let result = ctx.run(bash: "git tag -l")
        if result.succeeded {
            let tagList = result.stdout.components(separatedBy: "\n").filter({$0 != ""})
            return (tagList, nil)
        } else {
            return ([], formatErrorMsg(result.stderror))
        }
    }

    func deleteLocalTag(_ tag: String) -> String? {
        let result = ctx.run(bash: "git tag -d \(tag)")
        if result.succeeded {
            return nil
        } else {
            return result.stderror
        }
    }
    
    func deleteRemoteTag(_ tag: String, remote: String) -> String? {
        let result = ctx.run(bash: "git push \(remote)  :\(tag)")
        if result.succeeded {
            return nil
        } else {
            return result.stderror
        }
    }
    
    // MARK: gem
    
    func checkGemInstalled(_ name: String) -> Bool {
        let result = ctx.run(bash: "gem query \(name)")
        return result.succeeded
    }
    
    func checkPluginVersion(for plugin: String, version: String) -> Bool {
        let result = ctx.run(bash: "gem query \(plugin) -i -v \(version)")
        return result.succeeded
    }
    
    func installGem(_ gem: String, password: String) -> String? {
        let shellCommand = """
        echo "\(password)" | sudo -S gem install \(gem)
        """
        let result = ctx.run(bash: shellCommand)
        if result.succeeded {
            return nil
        } else {
            return formatErrorMsg(result.stderror)
        }
    }
    
    func uninstallGem(_ gem: String, password: String) {
        var shellCommand = """
        echo "\(password)" | sudo -S gem uninstall \(gem) -a
        """
        let result1 = ctx.run(bash: shellCommand)
        debugPrint("\(result1.succeeded):\(result1.stdout):\(result1.stderror)")
        
        shellCommand = "gem uninstall \(gem) -a"
        let result2 = ctx.run(bash: shellCommand)
        debugPrint("\(result2.succeeded):\(result2.stdout):\(result2.stderror)")
    }
    
    // MARK: other
    
    func openInFinder() {
        guard let workDir = self.workDir else { return }
        ctx.run(bash: "open \(workDir)")
    }
    
    func loadSpecRepos() -> ([SpecRepo], String?) {
        let result = ctx.run(bash: "pod tag repo-list --format=json")
        if result.succeeded {
            let repoListJSON = JSON(parseJSON: result.stdout)
            let repos = repoListJSON.arrayValue.map { SpecRepo($0) }
            return (repos, nil)
        } else {
            return ([], formatErrorMsg(result.stderror))
        }
    }
    
    func addSpecRepo(_ name: String, url: String, branch: String) -> String? {
        let result = ctx.run(bash: "pod repo add \(name) \(url) \(branch) --silent")
        if result.succeeded {
            return nil
        } else {
            return formatErrorMsg(result.stderror)
        }
    }
    
    func removeSpecRepo(_ name: String) -> String? {
        let result = ctx.run(bash: "pod repo remove \(name)")
        if result.succeeded {
            return nil
        } else {
            return formatErrorMsg(result.stderror)
        }
    }
    
    // MARK: - Private methods
    
    private func formatErrorMsg(_ error: String) -> String {
        error.regexReplace(with: outRegexPattern)
    }
}
