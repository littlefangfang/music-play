//
//  LyricTool.swift
//  music play
//
//  Created by xinyue-0 on 2017/2/23.
//  Copyright © 2017年 xinyue-0. All rights reserved.
//

import UIKit

class LyricTool: NSObject {
    
    static func getLyricArrWithURL(url: URL, songID: String, completeHandler:@escaping ([[String: String]])->Void) {
        
        let lrcDir = ((NSHomeDirectory() as NSString).appendingPathComponent("Documents") as NSString).appendingPathComponent("Lyrics")
        let fmr = FileManager.default
        let exists = fmr.fileExists(atPath: lrcDir)
        if !exists {
            do {
                try fmr.createDirectory(atPath: lrcDir, withIntermediateDirectories: true, attributes: nil)
            }catch{
                print("create Lyric directory error : \(error)")
            }
        }
        let lyricFilePath = (lrcDir as NSString).appendingPathComponent("\(songID).txt")
        if fmr.fileExists(atPath: lyricFilePath) {
            let data = NSData(contentsOfFile: lyricFilePath)
            if data != nil {
                let infoArr = formateLyric(lyricData: data as! Data)
                if infoArr != nil {
                    completeHandler(infoArr!)
                }
            }
        }else{
            let session = URLSession.shared
            let requst = URLRequest(url: url)
            session.dataTask(with: requst) { (data, resq, err) in
                if (resq as! HTTPURLResponse).statusCode != 200 {
                    print("resp:" + "\((resq as! HTTPURLResponse).statusCode)")
                    return
                }
                
                if err != nil {
                    print("get  lyric error: " + "\(err)")
                }
                
                if data != nil {
                    let infoArr = formateLyric(lyricData: data!)
                    if infoArr != nil {
                        (data! as NSData).write(toFile: lyricFilePath, atomically: true)
                        completeHandler(infoArr!)
                    }
                }
            }.resume()
        }
    }
    
    static fileprivate func formateLyric(lyricData: Data) -> [[String: String]]? {
        do {
            var originStr = String(data: lyricData, encoding: String.Encoding.utf8)
            originStr = (originStr! as NSString).replacingCharacters(in: NSMakeRange(0, 0), with: "<meta charset=\"UTF-8\">\n")
            originStr = originStr?.replacingOccurrences(of: "&#10;", with: "~~~I am a separate line~~~")
            let replacedData = originStr?.data(using: String.Encoding.utf8)
            
            let attributedStr = try! NSAttributedString(data: replacedData!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
            let str = attributedStr.string
            let d = str.data(using: String.Encoding.utf8)
            
            let json = try JSONSerialization.jsonObject(with: d!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String : AnyObject]
            let lyric = (json["showapi_res_body"] as! [String : AnyObject])["lyric"]  as? String
            
            if lyric == nil {
                return nil
            }
            
            let lyricArr = lyric!.components(separatedBy: "~~~I am a separate line~~~")
            var lyricInfoArr = [[String: String]]()
            
            for str in lyricArr {
                var dic = [String: String]()
                let strArr = str.components(separatedBy: "]")
                var timeStr = strArr[0]
                timeStr = timeStr.replacingOccurrences(of: "[", with: "")
                var content = " "
                if strArr.count > 1 {
                    content = strArr[1]
                }
                
                let pattern = "\\d{2}:\\d{2}.\\d{2}"
                do {
                    let regular = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
                    let matchCount = regular.numberOfMatches(in: timeStr, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSMakeRange(0, timeStr.characters.count))
                    
                    if matchCount > 0 {
                        dic["time"] = timeStr
                        dic["content"] = content
                        lyricInfoArr.append(dic)
                    }
                }catch{
                    print("match time error")
                }
            }
            
            return lyricInfoArr
            
        }catch {
            print("formate lyric error: \(error)")
            return nil
        }
    }
}


