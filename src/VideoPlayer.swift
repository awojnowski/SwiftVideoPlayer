//
//  VideoPlayer.swift
//  AWEasyVideoPlayer
//
//  Created by Aaron Wojnowski on 2014-06-03.
//  Copyright (c) 2014 Aaron. All rights reserved.
//

import AVFoundation
import CoreMedia
import UIKit

protocol VideoPlayerDelegate {
    
    func videoPlayer(videoPlayer: VideoPlayer, changedState: VideoPlayerState)
    func videoPlayer(videoPlayer: VideoPlayer, encounteredError: NSError)
    
}

enum VideoPlayerEndAction: Int {
    
    case Stop = 1
    case Loop
    
}

enum VideoPlayerState: Int {
    
    case Stopped = 1
    case Loading, Playing, Paused
    
}

class VideoPlayer: UIView {
    
    // - Getters & Setters
    
    // Public
    
    var delegate : VideoPlayerDelegate?
    
    var endAction : VideoPlayerEndAction
    var state : VideoPlayerState {
        didSet {
            
            switch (self.state) {
                case .Paused, .Stopped:
                    
                    self._actionButton?.removeTarget(self, action: Selector("pause"), forControlEvents: UIControlEvents.TouchUpInside)
                    self._actionButton?.addTarget(self, action: Selector("play"), forControlEvents: UIControlEvents.TouchUpInside)
                
                case .Loading, .Playing:
                    
                    self._actionButton?.removeTarget(self, action: Selector("play"), forControlEvents: UIControlEvents.TouchUpInside)
                    self._actionButton?.addTarget(self, action: Selector("pause"), forControlEvents: UIControlEvents.TouchUpInside)
                
            }
            
        }
    }
    
    var URL : NSURL? {
        didSet {
            
            self._destroyPlayer()
            
        }
    }
    
    var volume : Float {
        didSet {
            
            if self._player {
            
                self._player!.volume = self.volume
                
            }
            
        }
    }
    
    // Private
    
    var _player : AVPlayer?
    var _playerLayer : AVPlayerLayer?
    
    var _actionButton : UIButton?
    
    var _isBufferEmpty : Bool
    var _isLoaded : Bool
    
    // - Initializing
    
    deinit {
        
        self._destroyPlayer()
        
    }

    init(frame: CGRect) {
        
        self.endAction = VideoPlayerEndAction.Stop
        self.state = VideoPlayerState.Stopped;
        self.volume = 1.0;
        
        self._isBufferEmpty = false
        self._isLoaded = false
        
        super.init(frame: frame)
        
        let actionButton : UIButton = UIButton()
        self.addSubview(actionButton)
        self._actionButton = actionButton

    }
    
    // - Layout
    
    override func layoutSubviews() {
        
        self._actionButton!.frame = self.bounds
        
        if (self._playerLayer) {
            self._playerLayer!.frame = self.bounds
        }

    }
    
    
    // - Setup Player
    
    
    func _setupPlayer() {
        
        if !self.URL {
            return;
        }
        
        self._destroyPlayer()
        
        let playerItem : AVPlayerItem = AVPlayerItem(URL: self.URL!)
        
        let player : AVPlayer = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = AVPlayerActionAtItemEnd.None
        player.volume = self.volume
        self._player = player;
        
        let playerLayer : AVPlayerLayer = AVPlayerLayer(player: player)
        self.layer.addSublayer(playerLayer)
        self._playerLayer = playerLayer
        
        player.play()
        
        self._addObservers()
        self.setNeedsLayout()

    }

    func _destroyPlayer() {
        
        self._removeObservers();
        
        self._player = nil
        
        self._playerLayer?.removeFromSuperlayer()
        self._playerLayer = nil
        
        self._setStateNotifyingDelegate(VideoPlayerState.Stopped)
        
    }
    
    // - Player Notifications
    
    func playerFailed(notification: NSNotification) {
        
        self._destroyPlayer();
        self.delegate?.videoPlayer(self, encounteredError: NSError(domain: "VideoPlayer", code: 1, userInfo: [NSLocalizedDescriptionKey : "An unknown error occured."]))
        
    }
    
    func playerPlayedToEnd(notification: NSNotification) {
        
        switch self.endAction {
            
            case .Loop:
                
                self._player?.currentItem?.seekToTime(kCMTimeZero)
            
            case .Stop:
            
                self._destroyPlayer()
            
        }
        
    }
    
    // - Observers

    func _addObservers() {

        self._player?.addObserver(self, forKeyPath: "rate", options: nil, context: nil)
        
        self._player?.currentItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: nil, context: nil)
        self._player?.currentItem?.addObserver(self, forKeyPath: "status", options: nil, context: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerFailed:"), name: AVPlayerItemFailedToPlayToEndTimeNotification, object: self._player?.currentItem?)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerPlayedToEnd:"), name: AVPlayerItemDidPlayToEndTimeNotification, object: self._player?.currentItem?)
        
    }

    func _removeObservers() {

        self._player?.removeObserver(self, forKeyPath: "rate")
        
        self._player?.currentItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        self._player?.currentItem?.removeObserver(self, forKeyPath: "status")
        
        NSNotificationCenter.defaultCenter().removeObserver(self)

    }

    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: NSDictionary!, context: CMutableVoidPointer)  {

        let obj = object as? NSObject
        if obj == self._player? {
            
            if keyPath == "rate" {
                
                let rate = self._player?.rate
                if !self._isLoaded {
                    
                    self._setStateNotifyingDelegate(VideoPlayerState.Loading)
                    
                } else if rate == 1.0 {
                    
                    self._setStateNotifyingDelegate(VideoPlayerState.Playing)
                    
                } else if rate == 0.0 {
                    
                    if self._isBufferEmpty {
                        
                        self._setStateNotifyingDelegate(VideoPlayerState.Loading)
                        
                    } else {
                        
                        self._setStateNotifyingDelegate(VideoPlayerState.Paused)
                        
                    }
                    
                }
                
            }
            
        } else if obj == self._player?.currentItem? {
            
            if keyPath == "status" {
                
                let status : AVPlayerItemStatus? = self._player?.currentItem?.status
                if status == AVPlayerItemStatus.Failed {
                    
                    self._destroyPlayer()
                    self.delegate?.videoPlayer(self, encounteredError: NSError(domain: "VideoPlayer", code: 1, userInfo: [NSLocalizedDescriptionKey : "An unknown error occured."]))
                    
                } else if status == AVPlayerItemStatus.ReadyToPlay {
                    
                    self._isLoaded = true
                    self._setStateNotifyingDelegate(VideoPlayerState.Playing)
                    
                }

            } else if keyPath == "playbackBufferEmpty" {

                let empty : Bool? = self._player?.currentItem?.playbackBufferEmpty
                if empty {

                    self._isBufferEmpty = true

                } else {

                    self._isBufferEmpty = false
                    
                }
                
            }
            
        }

    }

    // - Actions

    func play() {

        switch self.state {

            case VideoPlayerState.Paused:

                self._player?.play()

            case VideoPlayerState.Stopped:

                self._setupPlayer();

            default:
                break

        }

    }

    func pause() {

        switch self.state {

            case VideoPlayerState.Playing, VideoPlayerState.Loading:
                
                self._player?.pause()
            
            default:
                break
            
        }
        
    }
    
    func stop() {
        
        if (self.state == VideoPlayerState.Stopped) {
            
            return
            
        }
        
        self._destroyPlayer()
        
    }
    
    // - Getters & Setters
    
    func _setStateNotifyingDelegate(state: VideoPlayerState) {
        
        self.state = state
        self.delegate?.videoPlayer(self, changedState: state)
        
    }

}
