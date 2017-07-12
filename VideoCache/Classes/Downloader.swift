//
//  Downloader.swift
//  Pods
//
//  Created by DirGoTii on 29/06/2017.
//
//

import Foundation
import ReactiveSwift

public enum Message {
    case data(Data), response(URLResponse)
}

public protocol Downloader {
    func download(_ url: String, range: Range<UInt64>) -> SignalProducer<Message, NSError>
}

