//
//  URL+Map.swift
//  Pods
//
//  Created by DirGoTii on 02/07/2017.
//
//

import Foundation

extension URL {
    var fakeTransform: URL {
        if var components = URLComponents(url: self, resolvingAgainstBaseURL: false) {
            components.scheme = map(scheme: components.scheme ?? "")
            return components.url ?? self
        }
        return self
    }
    
    func map(scheme: String) -> String {
        return ["https": "xxxxs", "http": "xxxx", "xxxx": "http", "xxxxs": "https"][scheme] ?? scheme
    }
}
