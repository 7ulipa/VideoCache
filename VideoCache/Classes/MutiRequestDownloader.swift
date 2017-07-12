//
//  MutiRequestDownloader.swift
//  Pods
//
//  Created by DirGoTii on 12/07/2017.
//
//

import Foundation
import ReactiveSwift
import Result

extension Downloader {
    public func multiRequest(maxRequestLength: UInt64 = 666666) -> Downloader {
        let result = MultiRequestDownloader()
        result.maxRequestLength = maxRequestLength
        result.downloader = self
        return result
    }
}

final class MultiRequestDownloader: Downloader {
    
    var maxRequestLength: UInt64 = 600 * 1024
    
    var downloader: Downloader = SimpleDownloader.shared
    
    func download(_ url: String, range: Range<UInt64>) -> SignalProducer<Message, NSError> {
        guard range.upperBound > range.lowerBound else {
            return SignalProducer.empty
        }
        return SignalProducer<Message, NSError> { (observer, dispose) in
            var offset = range.lowerBound
            var expectedOffset = range.lowerBound
            let (rangeSignal, rangeObserver) = Signal<Range<UInt64>, NoError>.pipe()
            
            let check = {
                if offset < expectedOffset || offset == range.upperBound {
                    rangeObserver.sendCompleted()
                } else {
                    let range: Range<UInt64> = offset ..< min(offset + self.maxRequestLength, range.upperBound)
                    expectedOffset = offset + UInt64(range.count)
                    rangeObserver.send(value: range)
                }
            }
            
            dispose.add(rangeSignal.flatMap(.concat) { (value) -> SignalProducer<Message, NSError> in
                return self.downloader.download(url, range: value).on(completed: check, value: {
                    switch $0 {
                    case .response(let response):
                        offset += UInt64(response.expectedContentLength)
                    default:
                        break
                    }
                })
                }.observe(observer))
            
            check()
        }
        
    }
}
