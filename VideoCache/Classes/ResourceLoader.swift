//
//  ResourceLoader.swift
//  Pods
//
//  Created by DirGoTii on 02/07/2017.
//
//

import Foundation
import AVFoundation

class ResourceLoader {
    static let shared = ResourceLoader()
    func load(request: AVAssetResourceLoadingRequest) -> Bool {
        if let url = request.request.url {
            CacheManager.shared.cache(for: url).load(request: request)
            return true
        }
        return false
    }
    
    func cancel(request: AVAssetResourceLoadingRequest) {
        if let url = request.request.url {
            CacheManager.shared.cache(for: url).cancel(request: request)
        }
    }
}
