//
//  ViewController.swift
//  SwiftVideoPlayerExample
//
//  Created by Aaron Wojnowski on 2014-06-03.
//  Copyright (c) 2014 Aaron. All rights reserved.
//

import UIKit

class ViewController: UIViewController, VideoPlayerDelegate {
    
    var videoPlayer : VideoPlayer?
    
    // - Initialization
    
    init(coder aDecoder: NSCoder!)  {
        super.init(coder: aDecoder)
        
        
    }
    
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        
        
    }
    
    // - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var videoPlayer = VideoPlayer(frame: CGRectZero)
        self.view!.addSubview(videoPlayer)
        self.videoPlayer = videoPlayer
        
        videoPlayer.URL = NSURL(string: "http://uploadingit.com/file/pkgz6mplwtodlzl6/Mac%20OS%20X%20Snow%20Leopard%20Intro%20Movie%20HD.mp4")
        videoPlayer.endAction = VideoPlayerEndAction.Stop
        videoPlayer.play()
        
    }
    
    override func viewDidLayoutSubviews()  {
        super.viewDidLayoutSubviews()
        
        self.videoPlayer!.frame = CGRect(x: (CGRectGetWidth(self.view!.bounds) - 280) / 2.0, y: (CGRectGetHeight(self.view!.bounds) - 280) / 2.0, width: 280, height: 280)
        
    }
    
    // - VideoPlayerDelegate
    
    func videoPlayer(videoPlayer: VideoPlayer, changedState: VideoPlayerState) {
        
        
        
    }
    
    func videoPlayer(videoPlayer: VideoPlayer, encounteredError: NSError) {
        
        UIAlertView(title: "Error", message: encounteredError.localizedDescription, delegate: nil, cancelButtonTitle: "Dismiss").show()
        
    }
    
}
