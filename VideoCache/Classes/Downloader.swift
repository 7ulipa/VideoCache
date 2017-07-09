//
//  Downloader.swift
//  Pods
//
//  Created by DirGoTii on 29/06/2017.
//
//

import Foundation
import ReactiveSwift

final class Downloader: NSObject {
    enum Message {
        case data(Data), response(URLResponse)
    }
    
    static let shared = Downloader()
    
    private lazy var session: URLSession = self.createSession()
    private let workQueue = OperationQueue()
    
    private func createSession() -> URLSession {
        let result = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: workQueue)
        return result
    }
    
    fileprivate var tasks: [Int: Observer<Message, NSError>] = [:]
    
    func download(_ url: String, from: UInt64) -> SignalProducer<Message, NSError> {
        return SignalProducer<Message, NSError> { (observer, dispose) in
            self.workQueue.addOperation {
                do {
                    guard let url = URL(string: url) else {
                        throw NSError(domain: "com.\(self)", code: 1024, userInfo: nil)
                    }
                    var request = URLRequest(url: url)
                    request.setValue("bytes=\(from)-", forHTTPHeaderField: "Range")
                    request.httpMethod = "GET"
                    
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

extension Downloader: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        tasks[dataTask.taskIdentifier]?.send(value: .data(data))
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            tasks[task.taskIdentifier]?.send(error: error as NSError)
        } else {
            tasks[task.taskIdentifier]?.sendCompleted()
        }
        tasks.removeValue(forKey: task.taskIdentifier)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        tasks[dataTask.taskIdentifier]?.send(value: .response(response))
        completionHandler(.allow)
    }
}
