//
//  PlayMusicViewController.swift
//  music play
//
//  Created by xinyue-0 on 2017/2/18.
//  Copyright © 2017年 xinyue-0. All rights reserved.
//

import UIKit

class PlayMusicViewController: UIViewController, StreamingAVPlayerDelegate {
    
    
    @IBOutlet var downloadProgressView: UIProgressView!
    @IBOutlet var playProgressSlider: UISlider!
    @IBOutlet var currentTimeLabel: UILabel!
    @IBOutlet var remainingTimeLabel: UILabel!
    @IBOutlet var playButton: UIButton!
    

    var url: URL!
    var session: URLSession!
    var player: StreamingAVPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        player = StreamingAVPlayer(name: "default")
        player.delegate = self
        
        let songArr = [url.absoluteString]
        let songNames = ["test"]
        let dirPath = ((NSHomeDirectory() as NSString).appendingPathComponent("Documents") as NSString).appendingPathComponent("Audios")
        player.setAudioFolderPath(dirPath, audioPaths: songArr, audioNames: songNames, start: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player.stop()
        player = nil
        UIApplication.shared.endReceivingRemoteControlEvents()
        resignFirstResponder()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Actions
    @IBAction func playSong(_ sender: UIButton) {
        if sender.isSelected == true {
            player.pause()
        }else{
            player.play()
        }
    }
    
    @IBAction func changeSliderValue(_ sender: UISlider) {
        player.setProgressInTermsOfSeconds(sender.value)
    }
    
    
    //MARK: - StreamingAVPlayerDelegate
    func streamAVPlayer(_ playerName: String!, updateAudioDuration seconds: Float) {
//        playProgressSlider.setValue(seconds, animated: true)
        playProgressSlider.maximumValue = seconds
        remainingTimeLabel.text = String(format: "%02d:%02d:%02d", Int(seconds) / 3600, Int(seconds) / 60 , Int(seconds) % 60)
    }
    
    func streamAVPlayer(_ playerName: String!, updateAudioName audioName: String!) {
        print("now play:" + playerName)
    }
    
    func streamAVPlayer(_ playerName: String!, updatePlayerStatus status: String!) {
        print("player status:" + status)
        if status == StreamingAVPlayer_Status_Playing {
            playButton.isSelected = true
        }else{
            playButton.isSelected = false
        }
    }
    
    func streamAVPlayer(_ playerName: String!, updateAudioDownloadDataLength length: Int, andDownloadPercentage percent: Float) {
        downloadProgressView.setProgress(percent, animated: true)
    }
    
    func streamAVPlayer(_ playerName: String!, updateAudioPositionSeconds seconds: Float, andPositionPercentage percent: Float) {
        playProgressSlider.setValue(seconds, animated: true)
        currentTimeLabel.text = String(format: "%02d:%02d:%02d", Int(seconds) / 3600, Int(seconds) / 60 , Int(seconds) % 60)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
