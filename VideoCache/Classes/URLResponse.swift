//
//  URLResponse.swift
//  Pods
//
//  Created by DirGoTii on 12/07/2017.
//
//

import Foundation

extension URLResponse {
    var totalLength: UInt64 {
        return UInt64(((self as? HTTPURLResponse)?.allHeaderFields.filter { ($0.key as? String ?? "").lowercased() == "content-range" }.first?.value as? String)?.components(separatedBy: "/").last ?? "0") ?? 0
    }
}
