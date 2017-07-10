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
    public static var downloader: Downloader {
        get {
            return _downloader ?? SimpleDownloader.shared
        }
        
        set {
            _downloader = newValue
        }
    }
}
