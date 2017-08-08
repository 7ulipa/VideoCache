//
//  CacheManager.swift
//  Pods
//
//  Created by DirGoTii on 02/07/2017.
//
//

import Foundation
import ReactiveSwift

public class CacheManager {
    public static let shared = CacheManager()
    
    init() {
        NotificationCenter.default.reactive.notifications(forName: .UIApplicationWillTerminate).observeValues { [weak self] (noti) in
            self?.deleteOldFiles()
        }
        NotificationCenter.default.reactive.notifications(forName: .UIApplicationDidEnterBackground).observeValues { [weak self] (noti) in
            self?.backgroundDeleteOldFiles()
        }
    }
    
    private func deleteOldFiles() {
        deleteOldFiles(with: nil)
    }
    
    private var backgroundTask: UIBackgroundTaskIdentifier!
    
    private func backgroundDeleteOldFiles() {
        func endBackgroundTask() {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            backgroundTask = UIBackgroundTaskInvalid
        }
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "DeleteOldFiles", expirationHandler: {
            endBackgroundTask()
        })
        deleteOldFiles {
            endBackgroundTask()
        }
    }
    
    private func deleteOldFiles(with complete: (() -> Void)?) {
        workQueue.async {
            do {
                try FileManager.default.contentsOfDirectory(atPath: VideoCacheSettings.kCachePath as String).forEach({ (dirname) in
                    let dirPath = VideoCacheSettings.kCachePath.appendingPathComponent(dirname)
                    if let record = CacheRecord(path: dirPath), record.isExpired() {
                        try FileManager.default.removeItem(atPath: dirPath)
                    }
                })
                complete?()
            } catch {
                NSLog((error as NSError).localizedDescription)
            }
        }
    }
    
    public func startPlay(url: URL) {
        workQueue.async {
            self.cache(for: url.fakeTransform).playing.value = true
        }
    }
    
    public func stopPlay(url: URL) {
        workQueue.async {
            self.cache(for: url.fakeTransform).playing.value = false
        }
    }
    
    public func startPrefetch(url: URL) {
        workQueue.async {
            self.cache(for: url.fakeTransform).prefetching.value = true
        }
    }
    
    public func stopPrefetch(url: URL) {
        workQueue.async {
            self.cache(for: url.fakeTransform).prefetching.value = false
        }
    }
    
    let workQueue = DispatchQueue(label: "com.\(CacheManager.self).workQueue")
    
    let caches = Atomic<[URL: CacheRecord]>([:])
    
    func cache(for URL: URL) -> CacheRecord {
        return caches.modify {
            if let result = $0[URL] {
                return result
            }
            let result = CacheRecord(url: URL)
            $0[URL] = result
            return result
        }
    }
}
