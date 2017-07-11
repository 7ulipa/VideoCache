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
    
    public func startPlay(url: URL) {
        cache(for: url).playing.value = true
    }
    
    public func stopPlay(url: URL) {
        cache(for: url).playing.value = false
    }
    
    public func startPrefetch(url: URL) {
        cache(for: url).prefetching.value = true
    }
    
    public func stopPrefetch(url: URL) {
        cache(for: url).prefetching.value = false
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
