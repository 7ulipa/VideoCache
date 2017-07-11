//
//  VideoCacheSettings.swift
//  Pods
//
//  Created by DirGoTii on 10/07/2017.
//
//

import Foundation

public class VideoCacheSettings {
    private static var _downloader: Downloader?
    static let kMCacheAge: Int = 60 * 60 * 24
    static let kCachePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("VideoCache") as NSString
    public static var downloader: Downloader {
        get {
            return _downloader ?? SimpleDownloader.shared
        }
        
        set {
            _downloader = newValue
        }
    }
}
