//
//  ViewController.swift
//  music play
//
//  Created by xinyue-0 on 2017/1/10.
//  Copyright © 2017年 xinyue-0. All rights reserved.
//  http://route.showapi.com/213-4?showapi_appid=30499&&showapi_sign=bd7693a43b504b91ab93edd5d7f1518e&&topid=5
/*
 3=欧美
 5=内地
 6=港台
 16=韩国
 17=日本
 18=民谣
 19=摇滚
 23=销量
 26=热歌
 */
import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var searchTextField: UITextField!
    let nameArray = ["欧美", "内地", "港台", "韩国", "日本", "民谣", "摇滚", "销量", "热歌"]
    let codeArray = ["3", "5", "6", "16", "17", "18", "19", "23", "26"]
    let topBaseURL = "http://route.showapi.com/213-4?showapi_appid=30499&&showapi_sign=bd7693a43b504b91ab93edd5d7f1518e&&topid="
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // test - start
//        let aStr = "&#32;"
//        let bStr = "&#10;"
//        
//        let a = try! NSAttributedString(data: aStr.data(using: String.Encoding.utf8)!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
//        let b = try! NSAttributedString(data: bStr.data(using: String.Encoding.utf8)!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
//        print(a.string + "------" + b.string)
//        if a == b {
//            print("equal")
//        }else{
//            print("diffrent")
//        }
        // test - end
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func tapSearchMusic(_ sender: Any) {
        
    }

    @IBAction func tapShowNewMusic(_ sender: Any) {
        
    }
    
    @IBAction func tapShowAllMusic(_ sender: Any) {
        
    }
    
    //MARK: UICollectionView datasource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "music_class_cell", for: indexPath) as! MusicCategoryCollectionViewCell
        cell.titleLabel.text = nameArray[indexPath.row]
        return cell
    }
    
    //MARK: UICollectionView delegete
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "show_music_list", sender: codeArray[indexPath.row])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "search" {
            
            let now = Date()
            let dfm = DateFormatter()
            dfm.dateFormat = "yyyyMMddHHmmss"
            let nowStr = dfm.string(from: now)
            
            let vc = segue.destination as! MusicListViewController
            var urlStr = String(format: "https://route.showapi.com/213-1?keyword=%@&page=1&showapi_appid=30499&showapi_timestamp=%@&showapi_sign=bd7693a43b504b91ab93edd5d7f1518e", searchTextField.text!, nowStr)
            urlStr = urlStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            vc.url = URL(string: urlStr)
            vc.isSearch = true
            vc.keyword = searchTextField.text!
        }else{
            let vc = segue.destination as! MusicListViewController
            let urlStr = topBaseURL + (sender as! String)
            vc.url = URL(string: urlStr)
        }
    }

}

