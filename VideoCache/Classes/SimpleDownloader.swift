//
//  SimpleDownloader.swift
//  Pods
//
//  Created by DirGoTii on 10/07/2017.
//
//

import Foundation
import ReactiveSwift

public final class SimpleDownloader: NSObject, Downloader {
    
    public static let shared = SimpleDownloader()
    
    private lazy var session: URLSession = self.createSession()
    private let workQueue = OperationQueue()
    
    public var requestSetup: ((inout URLRequest) -> Void)?
    public var HTTPHeaders: [String: String]?
    
    private func createSession() -> URLSession {
        let result = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: workQueue)
        return result
    }
    
    fileprivate var tasks: [Int: Observer<Message, NSError>] = [:]
    
    public func download(_ url: String, range: Range<UInt64>) -> SignalProducer<Message, NSError> {
        return SignalProducer<Message, NSError> { (observer, dispose) in
            self.workQueue.addOperation {
                do {
                    guard let url = URL(string: url) else {
                        throw NSError(domain: "com.\(self)", code: 1024, userInfo: nil)
                    }
                    var request = URLRequest(url: url)
                    
                    let upperBound = range.upperBound < UInt64.max ? "\(range.upperBound)" : ""
                    request.setValue("bytes=\(range.lowerBound)-\(upperBound)", forHTTPHeaderField: "Range")
                    self.HTTPHeaders?.forEach {
                        request.setValue($0.value, forHTTPHeaderField: $0.key)
                    }
                    request.httpMethod = "GET"
                    self.requestSetup?(&request)
                    
                    let task = self.session.dataTask(with: request)
                    self.tasks[task.taskIdentifier] = observer
                    
                    dispose.add {
                        task.cancel()
                        self.workQueue.addOperation {
                            self.tasks.removeValue(forKey: task.taskIdentifier)
                        }
                    }
                    task.resume()
                } catch {
                    observer.send(error: error as NSError)
                }
            }
        }
    }
}

extension SimpleDownloader: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        tasks[dataTask.taskIdentifier]?.send(value: .data(data))
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            tasks[task.taskIdentifier]?.send(error: error as NSError)
        } else {
            tasks[task.taskIdentifier]?.sendCompleted()
        }
        tasks.removeValue(forKey: task.taskIdentifier)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        tasks[dataTask.taskIdentifier]?.send(value: .response(response))
        completionHandler(.allow)
    }
}
