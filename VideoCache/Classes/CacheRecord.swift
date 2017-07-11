//
//  CacheRecord.swift
//  Pods
//
//  Created by DirGoTii on 29/06/2017.
//
//

import AVFoundation
import Foundation
import ReactiveSwift
import Result
import MobileCoreServices
import ReactiveCocoa

protocol RecordMeta {
    var url: URL { get set }
    var length: UInt64 { get set }
    var createDate: Date { get set }
    var mimeType: String { get set }
}

class AnyRecordMeta: NSObject, RecordMeta, NSCoding {
    var url: URL
    var length: UInt64
    var createDate: Date
    var mimeType: String
    
    required init?(coder aDecoder: NSCoder) {
        url = aDecoder.decodeObject(forKey: "url") as? URL ?? URL(fileURLWithPath: "")
        length = aDecoder.decodeObject(forKey: "length") as? UInt64 ?? 0
        createDate = aDecoder.decodeObject(forKey: "createDate") as? Date ?? Date()
        mimeType = aDecoder.decodeObject(forKey: "mimeType") as? String ?? ""
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(url, forKey: "url")
        aCoder.encode(length, forKey: "length")
        aCoder.encode(createDate, forKey: "date")
        aCoder.encode(mimeType, forKey: "mimeType")
    }
    
    init(url: URL) {
        self.url = url
        length = 0
        createDate = Date()
        mimeType = ""
    }
}

protocol CacheRecordDelegate: class {
    func CacheRecordDidChanged(_ record: CacheRecord)
}

final class CacheRecord {
    
    private static let sacredCount = MutableProperty(0)
    private static let hasSacredTask = CacheRecord.sacredCount.producer.map { $0 > 0 }
    
    private let path: String
    private let metaPath: String
    private let contentPath: String
    
    private let (dataChangedSignal, dataChangedObserver) = Signal<(), NoError>.pipe()
    
    private lazy var requestLoader: Action<AVAssetResourceLoadingRequest, (), NoError> = self.createRequestLoader()
    
    private var downloadedLength: UInt64 = 0
    
    private let completed = MutableProperty(false)
    
    private let workQueue = DispatchQueue(label: "com.\(CacheRecord.self).workQueue")
    
    private var meta: RecordMeta
    
    let playing = MutableProperty(false)
    let prefetching = MutableProperty(false)
    
    init(url: URL) {
        let url = url.fakeTransform
        path = CacheRecord.path(for: url)
        metaPath = (path as NSString).appendingPathComponent("meta")
        contentPath = (path as NSString).appendingPathComponent("content")
        
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        
        if let meta = NSKeyedUnarchiver.unarchiveObject(withFile: metaPath) as? RecordMeta {
            self.meta = meta
        } else {
            meta = AnyRecordMeta(url: url)
            NSKeyedArchiver.archiveRootObject(meta, toFile: metaPath)
        }
        
        if !FileManager.default.fileExists(atPath: contentPath) {
            FileManager.default.createFile(atPath: contentPath, contents: nil, attributes: nil)
        } else {
            if let handler = FileHandle(forReadingAtPath: contentPath) {
                downloadedLength = handler.seekToEndOfFile()
                handler.closeFile()
                if downloadedLength > 0 && downloadedLength == meta.length {
                    completed.value = true
                }
            }
        }
        
        SignalProducer.combineLatest(playing.producer, requestLoader.isExecuting.producer, completed.producer)
            .map { ($0.0 || $0.1) && !$0.2 }
            .skip(first: 1)
            .skipRepeats()
            .startWithValues { (value) in
                CacheRecord.sacredCount.modify {
                    if value {
                        $0 += 1
                    } else {
                        $0 -= 1
                    }
                }
        }
        
        SignalProducer.combineLatest(playing.producer, requestLoader.isExecuting.producer, prefetching.producer, CacheRecord.hasSacredTask, completed.producer)
            .map { !$0.4 && ($0.0 || $0.1 || ($0.2 && !$0.3)) }
            .skipRepeats()
            .startWithValues { [weak self] (value) in
                if value {
                    self?.startCaching()
                } else {
                    self?.stopCaching()
                }
        }
    }
    
    init?(path: String) {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        self.path = path
        metaPath = (path as NSString).appendingPathComponent("meta")
        contentPath = (path as NSString).appendingPathComponent("content")
        if let meta = NSKeyedUnarchiver.unarchiveObject(withFile: metaPath) as? RecordMeta {
            self.meta = meta
        } else {
            return nil
        }
    }
    
    private static func path(for url: URL) -> String {
        return VideoCacheSettings.kCachePath.appendingPathComponent(url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "tmp")
    }
    
    private var downloading = false
    
    private var downloadDisposable: Disposable?
    
    private func _stopCaching() {
        downloadDisposable?.dispose()
    }
    
    private func _startCaching() {
        guard !self.downloading && !self.completed.value else {
            return
        }
        self.downloading = true
        guard let writer = FileHandle(forUpdatingAtPath: self.contentPath) else {
            self.downloading = false
            return
        }
        
        writer.seek(toFileOffset: self.downloadedLength)
        
        downloadDisposable = VideoCacheSettings.downloader.download(self.meta.url.absoluteString, from: self.downloadedLength).start { (event) in
            switch event {
            case .value(let value):
                switch value {
                case .data(let data):
                    writer.write(data)
                    self.downloadedLength = writer.offsetInFile
                    self.dataChangedObserver.send(value: ())
                case .response(let response):
                    self.meta.length = max(UInt64(response.expectedContentLength), self.meta.length)
                    self.meta.mimeType = response.mimeType ?? ""
                    NSKeyedArchiver.archiveRootObject(self.meta, toFile: self.metaPath)
                    self.dataChangedObserver.send(value: ())
                }
            case .failed, .interrupted:
                self.downloading = false
            case .completed:
                self.downloading = false
                self.completed.value = true
            }
        }
    }
    
    private lazy var dataChanged: SignalProducer<(), NoError> = self.createDataChanged()
    private func createDataChanged() -> SignalProducer<(), NoError> {
        return SignalProducer(dataChangedSignal).prefix(value: ())
    }
    
    private func createRequestLoader() -> Action<AVAssetResourceLoadingRequest, (), NoError> {
        return Action<AVAssetResourceLoadingRequest, (), NoError> { (input) -> SignalProducer<(), NoError> in
            return SignalProducer<(), NoError> { (observer, dispose) in
                dispose.add(self.dataChanged.startWithValues {
                    self.workQueue.async {
                        if self.process(request: input) {
                            observer.sendCompleted()
                        }
                    }
                })
                
                dispose.add(self.cancelSignal.filter { $0 === input }.observeValues({ (_) in
                    observer.sendCompleted()
                }))
            }
        }
    }
    
    private func process(request: AVAssetResourceLoadingRequest) -> Bool {
        if let infoRequest = request.contentInformationRequest {
            if meta.length > 0 {
                infoRequest.contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, meta.mimeType as CFString, nil)?.takeUnretainedValue() as String?
                infoRequest.contentLength = Int64(meta.length)
                infoRequest.isByteRangeAccessSupported = true
                request.finishLoading()
                return true
            }
        } else if let dataRequest = request.dataRequest {
            if downloadedLength > UInt64(dataRequest.currentOffset) {
                if let fileHandle = FileHandle(forReadingAtPath: self.contentPath) {
                    fileHandle.seek(toFileOffset: UInt64(dataRequest.currentOffset))
                    let data = fileHandle.readData(ofLength: Int(min(UInt64(dataRequest.requestedOffset + Int64(dataRequest.requestedLength)), downloadedLength) - UInt64(dataRequest.currentOffset)))
                    dataRequest.respond(with: data)
                    if dataRequest.currentOffset >= dataRequest.requestedOffset + Int64(dataRequest.requestedLength) {
                        request.finishLoading()
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private let (cancelSignal, cancelObserver) = Signal<AVAssetResourceLoadingRequest, NoError>.pipe()
    
    func load(request: AVAssetResourceLoadingRequest, for asset: AVURLAsset) {
        if !process(request: request) {
            requestLoader.apply(request).take(during: asset.reactive.lifetime).start()
        }
    }
    
    func cancel(request: AVAssetResourceLoadingRequest) {
        cancelObserver.send(value: request)
    }
    
    func stopCaching() {
        workQueue.async(execute: _stopCaching)
    }
    
    func startCaching() {
        workQueue.async(execute: _startCaching)
    }
    
    func isExpired() -> Bool {
        let expirationDate = Date(timeIntervalSinceNow: -(Double)(VideoCacheSettings.kMCacheAge))
        return meta.createDate.compare(expirationDate) == .orderedAscending
    }
}
