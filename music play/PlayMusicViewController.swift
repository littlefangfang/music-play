//
//  PlayMusicViewController.swift
//  music play
//
//  Created by xinyue-0 on 2017/2/18.
//  Copyright © 2017年 xinyue-0. All rights reserved.
//

import UIKit

class PlayMusicViewController: UIViewController, StreamingAVPlayerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet var downloadProgressView: UIProgressView!
    @IBOutlet var playProgressSlider: UISlider!
    @IBOutlet var currentTimeLabel: UILabel!
    @IBOutlet var remainingTimeLabel: UILabel!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var lyricTable: UITableView!
    @IBOutlet var coverImageView: UIImageView!

    var session: URLSession!
    var player: StreamingAVPlayer!
    var lyricInfo: [[String: String]]?
    var currentLine: Int!
    var songInfoArr: [[String: String]]?
    var playIndex: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lyricTable.dataSource = self
        lyricTable.delegate = self
        currentLine = 0
        
        player = StreamingAVPlayer.shared()
        player.stop()
        player.delegate = self
        
        var songArr = [String]()
        var songNames = [String]()
        var singerNames = [String]()
        
        for i in 0..<songInfoArr!.count {
            let songInfoDic = songInfoArr![i]
            let songUrl = songInfoDic["url"]!
            let songName = songInfoDic["songName"]!
            let singerName = songInfoDic["singerName"]!
            songArr.append(songUrl)
            songNames.append(songName)
            singerNames.append(singerName)
        }
//        let songArr = [url.absoluteString]
//        let songNames = ["test"]
        let dirPath = ((NSHomeDirectory() as NSString).appendingPathComponent("Documents") as NSString).appendingPathComponent("Audios")
        player.setPlayerName("default")
        player.setAudioFolderPath(dirPath, audioPaths: songArr, audioNames: songNames, singerNames: singerNames, start: playIndex)
        playSong(playButton)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
    
    @IBAction func playPrevious(_ sender: Any) {
        player.previous()
    }
    
    @IBAction func playNext(_ sender: Any) {
        player.next()
    }
    
    //MARK: - Helper
    fileprivate func getAlbumCover(coverImagePath: String) {
        
        let imgName = (coverImagePath as NSString).lastPathComponent
        let path = ((NSHomeDirectory() as NSString).appendingPathComponent("Documents") as NSString).appendingPathComponent(imgName)
        let img = UIImage(contentsOfFile: path)
        
        if img == nil {
            DispatchQueue.global().async {[unowned self] in
                let imgUrl = URL(string: coverImagePath)
                do {
                    let imgData = try Data(contentsOf: imgUrl!)
                    (imgData as NSData).write(toFile: path, atomically: true)
                    
                    DispatchQueue.main.async { [unowned self] in
                        self.coverImageView.image = UIImage(data: imgData)
                        self.player.coverImage = UIImage(data: imgData)
                    }
                    
                }catch {
                    print("get image error")
                }
            }
        }else{
            coverImageView.image = img
            player.coverImage = img
        }
            
        
    }
    
    fileprivate func getLrc(songID: String) {
        
        let now = Date()
        let dfm = DateFormatter()
        dfm.dateFormat = "yyyyMMddHHmmss"
        let dateStr = dfm.string(from: now)
        
        var path = String(format: "https://route.showapi.com/213-2?musicid=%@&showapi_appid=30499&showapi_timestamp=%@&showapi_sign=bd7693a43b504b91ab93edd5d7f1518e", songID, dateStr)
        path = path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let lrcURL = URL(string: path)!
        
        LyricTool.getLyricArrWithURL(url: lrcURL, songID: songID) { [weak self] (lyricInfo) -> Void in
            self?.lyricInfo = lyricInfo
            DispatchQueue.main.async { [weak self] in
                self?.lyricTable.reloadData()
            }
        }
    }
    
    fileprivate func setCurrentPlayLineWith(str: String) {
        if lyricInfo == nil {
            return
        }
        
        if player.currentTime == 0 {
            return
        }
        
        if currentLine <= 0 {
            currentLine = 1
        }
        
        let dfm = DateFormatter()
        dfm.dateFormat = "mm:ss.SS"
        
        let currentMusicTime = dfm.date(from: str)!
        let currentLineTime = dfm.date(from: (lyricInfo?[currentLine]["time"])!)!
        
        if currentLine + 1 >= lyricInfo!.count {
            return
        }
        
        let nextLineTime = dfm.date(from: (lyricInfo?[currentLine + 1]["time"])!)!
        
        if currentLineTime.timeIntervalSince1970 <= currentMusicTime.timeIntervalSince1970 && nextLineTime.timeIntervalSince1970 > currentMusicTime.timeIntervalSince1970 {
//            print(currentLine)
        }else if currentMusicTime.timeIntervalSince1970 < currentLineTime.timeIntervalSince1970 {
            currentLine = currentLine - 1
//            print(currentLine)
//            setCurrentPlayLineWith(str: str)
        }else if currentMusicTime.timeIntervalSince1970 >= nextLineTime.timeIntervalSince1970 {
            currentLine = currentLine + 1
            setCurrentPlayLineWith(str: str)
        }
    }
    
    
    //MARK: - StreamingAVPlayerDelegate
    func streamAVPlayer(_ playerName: String!, updateAudioDuration seconds: Float) {
//        playProgressSlider.setValue(seconds, animated: true)
        playProgressSlider.maximumValue = seconds
        remainingTimeLabel.text = String(format: "%02d:%02d:%02d", Int(seconds) / 3600, Int(seconds) / 60 , Int(seconds) % 60)
    }
    
    func streamAVPlayer(_ playerName: String!, updateAudioName audioName: String!, andCurrentPlay idx: Int) {
        print("now play:" + audioName)
        if songInfoArr != nil {
            let currentSongInfoDic = songInfoArr![idx]
            let songId = currentSongInfoDic["songID"]!
            let coverImagePath = currentSongInfoDic["coverImagePath"]!
            currentLine = 1
            getLrc(songID: songId)
            getAlbumCover(coverImagePath: coverImagePath)
        }
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
        if percent >= 0 && percent < 1 {
            downloadProgressView.setProgress(percent, animated: true)
        }else{
            downloadProgressView.setProgress(1.0, animated: false)
        }
    }
    
    func streamAVPlayer(_ playerName: String!, updateAudioPositionSeconds seconds: Float, andPositionPercentage percent: Float) {
        playProgressSlider.setValue(seconds, animated: true)
        currentTimeLabel.text = String(format: "%02d:%02d:%02d", Int(seconds) / 3600, Int(seconds) / 60 , Int(seconds) % 60)
        
        if lyricInfo != nil {
            let currentTimeStr = String(format: "%02d:%02d.%02d", Int(seconds) / 60, Int(seconds) % 60, Int((seconds - Float(Int(seconds))) * 100))
            setCurrentPlayLineWith(str: currentTimeStr)
            lyricTable.scrollToRow(at: IndexPath(row: currentLine, section: 0), at: UITableViewScrollPosition.middle, animated: true)
            
            lyricTable.reloadData()
            
            let cell = lyricTable.cellForRow(at: IndexPath(row: currentLine, section: 0)) as? LyricCell
            if cell != nil {
                cell!.titleLabel.textColor = UIColor.red
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if lyricInfo != nil {
            return lyricInfo!.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = lyricTable.dequeueReusableCell(withIdentifier: "lrcCell", for: indexPath) as! LyricCell
        cell.titleLabel.text = lyricInfo![indexPath.row]["content"]
        cell.titleLabel.textColor = UIColor.black
        return cell
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

class LyricCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
}
