//
//  Store.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/6/7.
//

import Foundation

final class Store: ObservableObject {
    @Published var specRepos: [SpecRepo] = []
    @Published var selectedSpecRepo: String = "git@techgit.meitu.com:iosmodules/specs.git"
//    @Published var selectedSpecRepo: SpecRepo?
    
    private var applicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    private let filename = "repos.json"

    private var databaseFileUrl: URL {
        let dirUrl = applicationSupportDirectory.appendingPathComponent("CocoaPodsTag")
        if !FileManager.default.fileExists(atPath: dirUrl.path) {
            try? FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)
        }
        return dirUrl.appendingPathComponent(filename)
    }
    
    // MARK: - Init

    init() {
        specRepos = []
    }
    
    // MARK: - Private methods
    
    private func loadSpecRepos(from storeFileData: Data) -> [SpecRepo] {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([SpecRepo].self, from: storeFileData)
        } catch {
            debugPrint(error)
            return []
        }
    }
    
    // MARK: - Public methods
    
    func add(specRepo: SpecRepo) {
        specRepos.append(specRepo)
        save()
    }
    
    func removeSpecRepo(for id: SpecRepo.ID) {
        specRepos.removeAll { repo in
            repo.id == id
        }
        save()
    }
    
    func removeInvalidSpecRepos() -> [SpecRepo] {
        let (repos, error) = Command.sharedInstance.loadSpecRepos()
        if error != nil {
            return specRepos
        }
        return specRepos.filter { repo in
            repos.contains { r in
                r.name == repo.name && r.url == repo.url
            }
        }
    }
    
    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(specRepos)
            if FileManager.default.fileExists(atPath: databaseFileUrl.path) {
                try FileManager.default.removeItem(at: databaseFileUrl)
            }
            try data.write(to: databaseFileUrl)
        } catch {
            debugPrint("保存失败")
        }
    }
}
