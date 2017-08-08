//
//  DispatchQueue+Scheduler.swift
//  Pods
//
//  Created by DirGoTii on 02/07/2017.
//
//

import Foundation
import ReactiveSwift

extension DispatchQueue: Scheduler {
    public func schedule(_ action: @escaping () -> Void) -> Disposable? {
        var canceled = false
        async {
            if !canceled {
                action()
            }
        }
        return AnyDisposable {
            canceled = true
        }
    }
}

