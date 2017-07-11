//
//  ViewController.swift
//  CachableAVAsset
//
//  Created by DirGoTii on 06/29/2017.
//  Copyright (c) 2017 DirGoTii. All rights reserved.
//

import UIKit
import VideoCache
import AVFoundation

class ViewController: UIViewController {
    
    var player: AVPlayer!
	
    let asset = AutoURLAsset(url: URL(string: "http://mp4.28mtv.com:9090/mp43/4128-%E9%83%AD%E9%9D%99-%E5%BF%83%E5%A2%99[68mtv.com].mp4")!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        let layer = AVPlayerLayer(player: player)
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        
        asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            let result = self.asset.statusOfValue(forKey: "playable", error: nil)
            if result == .loaded && self.asset.isPlayable {
                DispatchQueue.main.async {
                    debugPrint("dirgotii: play")
                    self.player.play()
                }
            }
            
        }
    }
}

