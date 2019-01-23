//
//  ViewController.swift
//  MusicBeats
//
//  Created by Si Beats on 2017-05-28.
//  Copyright © 2018 Si Beats. All rights reserved.
//

import UIKit
import MediaPlayer
import Phunware

class ViewController: UIViewController, MPMediaPickerControllerDelegate, AVAudioPlayerDelegate, PWInterstitialDelegate {
    
    var banner: PWBanner!
    var interstitial: PWInterstitial!
    
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var backgroundAlbumImageView: UIImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var songMetadataLabel: UILabel!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var powerSlider: UISlider!
    var mediaPlayer: AVAudioPlayer?, mediaPicker: MPMediaPickerController?, meterTable = MeterTable()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let config = PlacementRequestConfig(accountId: 174812, zoneId: 335387, width:nil, height:nil, customExtras:nil)
        let session = AVAudioSession.sharedInstance()
        let categoryPlayback = AVAudioSession.Category.playback
        let modeDefault = AVAudioSession.Mode.default
        let catOptions = AVAudioSession.CategoryOptions.defaultToSpeaker
        do {
            try? session.setCategory(categoryPlayback, mode: modeDefault, options: catOptions)
        } catch {
            print("No playback audio")
        }
        // Do any additional setup after loading the view, typically from a nib.
        albumImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.albumTapped)))
        albumImageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ViewController.albumHeld)))
        updateNowPlayingItem(nil)
        updatePlaybackState()
        Timer.scheduledTimer(timeInterval: 0.005, target: self, selector: #selector(ViewController.monitorAudioMeter), userInfo: nil, repeats: true)
        
        Phunware.requestPlacement(with: config) { response in
            switch response {
            case .success(_ , let placements):
                guard placements.count == 1 else {
                    // error
                    return
                }
                guard placements[0].isValid else {
                    // error
                    return
                }
                self.banner = PWBanner(placement:placements[0], parentViewController:self, position:Positions.BOTTOM_CENTER)
            case .badRequest(let statusCode, let responseBody):
                return
            case .invalidJson(let responseBody):
                return
            case .requestError(let error):
                return
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func albumTapped() {
        if let mediaPlayer = mediaPlayer {
            if mediaPlayer.isPlaying {
                mediaPlayer.pause()
            } else {
                mediaPlayer.play()
            }
        }
        updatePlaybackState()
        
    }
    
    
    @objc func albumHeld() {
        pickSong()
    }
    
    func pickSong() {
        let config = PlacementRequestConfig(accountId: 174812, zoneId: 335348, width:320, height:50, customExtras:nil)
        

        mediaPicker = MPMediaPickerController(mediaTypes: .anyAudio)
        mediaPicker!.delegate = self
        mediaPicker!.allowsPickingMultipleItems = false
        mediaPicker!.showsCloudItems = false
        mediaPicker!.showsItemsWithProtectedAssets = false
        present(mediaPicker!, animated: true, completion: nil)
        Phunware.requestPlacement(with: config) { response in
            switch response {
            case .success(_ , let placements):
                guard placements.count == 1 else {
                    return
                }
                
                guard placements[0].isValid else {
                    return
                }
                if(placements[0].body != nil && placements[0].body != ""){
                    self.interstitial = PWInterstitial(placement:placements[0], parentViewController:self, delegate:self, respectSafeAreaLayoutGuide:true)
                }
            default:
                return
            }
        }
    }
    
    
    // MARK: - Media Picker Controller Delegate
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
        self.mediaPicker = nil
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        if mediaItemCollection.count < 1 { return }
        let song = mediaItemCollection.items[0]
        mediaPicker.dismiss(animated: true, completion: nil)
        self.mediaPicker = nil
        mediaPlayer?.stop()
        if let url = song.assetURL {
            self.mediaPlayer = try? AVAudioPlayer(contentsOf: url)
            if self.mediaPlayer != nil {
                self.mediaPlayer!.prepareToPlay()
                self.mediaPlayer!.delegate = self
                self.mediaPlayer!.play()
                self.mediaPlayer!.isMeteringEnabled = true
                updatePlaybackState()
                updateNowPlayingItem(song)
            } else {
                fatalError("An error occurred while attempting to load that song. (no player created)")
            }
        } else {
            fatalError("An error occurred while attempting to load that song. (no asset URL)")
        }
    }
    
    func updateNowPlayingItem(_ song: MPMediaItem?) {
        songTitleLabel.text = song?.title ?? "No Title"
        songMetadataLabel.text = "\(song?.albumArtist ?? "Unknown Artist") — \(song?.albumTitle ?? "Unknown Album")"
        albumImageView.image = song?.artwork?.image(at: albumImageView.bounds.size)
        backgroundAlbumImageView.image = song?.artwork?.image(at: backgroundAlbumImageView.bounds.size)
    }
    
    func updatePlaybackState() {
        UIView.animate(withDuration: 0.2, animations: {
            var isPlaying = false
            if let mediaPlayer = self.mediaPlayer { isPlaying = mediaPlayer.isPlaying }
            self.albumImageView.alpha = isPlaying ? 1 : 0.3
        })
    }
    
    var lastPower: Float = 0
    
    @objc func monitorAudioMeter() {
        if let player = mediaPlayer {
            player.updateMeters()
            var totalPeakPower: Float = 0
            for i in 0 ..< player.numberOfChannels {
                totalPeakPower += player.peakPower(forChannel: i)
            }
            let peakPower = meterTable?.ValueAt(totalPeakPower / Float(player.numberOfChannels)) ?? 0
            let powerA = peakPower
            let power = max(0, powerA - lastPower)
            lastPower = powerA - 0.005
            if power > 0.02 {
                // TODO: Time between beats so that we don't show like 69,000 at once (e.g. resuming playback, jumpy part of a song)
                showBeat(hard: power > 0.18)
            }
            powerSlider.value = powerA
        }
    }
    
    private var isAnimatingBeatAlbumArtwork = false
    
    func showBeat(hard: Bool) {
        let beatView = UIView(frame: albumImageView.frame)
        albumImageView.superview!.insertSubview(beatView, at: 0)
        beatView.backgroundColor = UIColor(white: 1, alpha: hard ? 0.45 : 0.1)
        beatView.layer.cornerRadius = 10
        UIView.animate(withDuration: 1, animations: {
            beatView.alpha = 0
            beatView.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        })
        if !isAnimatingBeatAlbumArtwork {
            isAnimatingBeatAlbumArtwork = true
            UIView.animate(withDuration: 0.15, animations: {
                self.albumImageView.transform = CGAffineTransform.identity.scaledBy(x: 1.05, y: 1.05)
            }, completion: { _ in
                self.albumImageView.transform = .identity
                self.isAnimatingBeatAlbumArtwork = false
            })
        }
        HapticController.shared.playHapticBeat(hard: hard)
    }
    
    // MARK: Audio Player Delegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updateNowPlayingItem(nil)
        updatePlaybackState()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        updateNowPlayingItem(nil)
        updatePlaybackState()
    }
    func interstitialReady(_ interstitial: PWInterstitial) {
        interstitial.display()
        print("ready");
    }
    
    func interstitialFailedToLoad(_ interstitial: PWInterstitial) {
        print("failed");
    }
    
    func interstitialClosed(_ interstitial: PWInterstitial) {
        print("close");
    }
    
    func interstitialStartLoad(_ interstitial: PWInterstitial) {
        print("start load");
    }
    

}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
