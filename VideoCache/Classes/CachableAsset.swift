//
//  CachableAsset.swift
//  Pods
//
//  Created by DirGoTii on 02/07/2017.
//
//

import Foundation
import AVFoundation
import ReactiveSwift
import Result

public class CachableURLAsset: AVURLAsset {
    let resourceLoadQueue = DispatchQueue(label: "com.\(CachableURLAsset.self).workQueue")
    let (cancelSignal, cancelObserver) = Signal<AVAssetResourceLoadingRequest, NoError>.pipe()
    
    fileprivate let originURL: URL
    
    override init(url URL: URL, options: [String : Any]? = nil) {
        originURL = URL
        super.init(url: URL.fakeTransform, options: options)
        resourceLoader.setDelegate(self, queue: resourceLoadQueue)
    }
}

public class AutoURLAsset: CachableURLAsset {
    override init(url URL: URL, options: [String : Any]? = nil) {
        super.init(url: URL, options: options)
        CacheManager.shared.startPlay(url: originURL)
    }
    
    deinit {
        CacheManager.shared.stopPlay(url: originURL)
    }
}

extension CachableURLAsset: AVAssetResourceLoaderDelegate {
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        debugPrint("load \(loadingRequest.desc)")
        return ResourceLoader.shared.load(request: loadingRequest, for: self)
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        debugPrint("cancel \(loadingRequest.desc)")
        ResourceLoader.shared.cancel(request: loadingRequest)
    }
}

extension AVAssetResourceLoadingRequest {
    var desc: String {
        if contentInformationRequest != nil {
            return "dirgotii: contentInformationRequest"
        } else if let dataRequest = dataRequest {
            return "dirgotii: dataRequest \(dataRequest.requestedOffset) - \(dataRequest.requestedOffset + Int64(dataRequest.requestedLength))"
        }
        return ""
    }
}
