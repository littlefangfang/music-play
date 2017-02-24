//
//  LyricTool.swift
//  music play
//
//  Created by xinyue-0 on 2017/2/23.
//  Copyright © 2017年 xinyue-0. All rights reserved.
//

import UIKit

class LyricTool: NSObject {
    
    static func getLyricArrWithURL(url: URL, completeHandler:@escaping ([[String: String]])->Void) {
        let session = URLSession.shared
        let requst = URLRequest(url: url)
        session.dataTask(with: requst) { (data, resq, err) in
            if (resq as! HTTPURLResponse).statusCode != 200 {
                print("resp:" + "\((resq as! HTTPURLResponse).statusCode)")
                return
            }
            
            if err != nil {
                print("error: " + "\(err)")
            }
            
            do {
                var originStr = String(data: data!, encoding: String.Encoding.utf8)
                originStr = (originStr! as NSString).replacingCharacters(in: NSMakeRange(0, 0), with: "<meta charset=\"UTF-8\">\n")
                originStr = originStr?.replacingOccurrences(of: "&#10;", with: "~~~I am a separate line~~~")
                let replacedData = originStr?.data(using: String.Encoding.utf8)
                
                let attributedStr = try! NSAttributedString(data: replacedData!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                let str = attributedStr.string
                let d = str.data(using: String.Encoding.utf8)
                
                let json = try JSONSerialization.jsonObject(with: d!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String : AnyObject]
                let lyric = (json["showapi_res_body"] as! [String : AnyObject])["lyric"]  as! String
                
                let lyricArr = lyric.components(separatedBy: "~~~I am a separate line~~~")
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
                    if timeStr.contains("0") && !timeStr.contains("offset") {
                        dic["time"] = timeStr
                        dic["content"] = content
                        lyricInfoArr.append(dic)
                    }
                }
                completeHandler(lyricInfoArr)
            }catch {
                
            }
            
        }.resume()
    }
}


