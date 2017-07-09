//
//  CacheManager.swift
//  Pods
//
//  Created by DirGoTii on 02/07/2017.
//
//

import Foundation
import ReactiveSwift

class CacheManager {
    static let shared = CacheManager()
    
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
