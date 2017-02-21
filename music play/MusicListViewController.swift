//
//  MusicListViewController.swift
//  music play
//
//  Created by xinyue-0 on 2017/1/10.
//  Copyright © 2017年 xinyue-0. All rights reserved.
//

import UIKit

class MusicListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView!
    var url: URL?
    var dataArray: [AnyObject]?
    var session : URLSession!
    var isSearch = false
    var hasNext = false
    var keyword : String?
    var nextPage : Int?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        loadMusicList()
    }
    
    
    fileprivate func loadMusicList() {
        session = URLSession.shared
        let request = URLRequest(url: url!)
        session.dataTask(with: request) { (data, resp, error) in
            do {
                let str = String(data: data!, encoding: String.Encoding.utf8) ?? "aaa"
                let d = str.data(using: String.Encoding.utf8)
                var dic = try JSONSerialization.jsonObject(with: d!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: AnyObject]
                if self.isSearch == false {
                    self.dataArray = ((dic["showapi_res_body"] as? [String: Any])?["pagebean"] as! [String: Any])["songlist"] as? [AnyObject]
                }else{
                    if self.dataArray == nil {
                        self.dataArray = ((dic["showapi_res_body"] as? [String: Any])?["pagebean"] as! [String: Any])["contentlist"] as? [AnyObject]
                    }else{
                        let arr = ((dic["showapi_res_body"] as! [String: AnyObject])["pagebean"] as! [String: AnyObject])["contentlist"] as! [AnyObject]
                        self.dataArray!.append(contentsOf: arr)
                    }
                    
                    let allPages = ((((dic["showapi_res_body"] as? [String: Any])?["pagebean"] as! [String: AnyObject])["allPages"]) as! NSNumber).intValue
                    let currentPage = ((((dic["showapi_res_body"] as? [String: Any])?["pagebean"] as! [String: AnyObject])["currentPage"]) as! NSNumber).intValue
                    if allPages == currentPage {
                        self.hasNext = false
                    }else{
                        self.hasNext = true
                        self.nextPage = currentPage + 1
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }catch{
                print(error)
            }
            }.resume()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: UITableView datasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if dataArray != nil {
            return dataArray!.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "music_detail_cell", for: indexPath) as! MusicDetailTableViewCell
        
        cell.songnameLabel.text = (dataArray?[indexPath.row] as! [String : AnyObject])["songname"] as? String
        cell.singernameLabel.text = (dataArray?[indexPath.row] as! [String : AnyObject])["singername"] as? String
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "s", sender: indexPath.row)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - UIScreen.main.bounds.height - 10 {
            if hasNext == true {
                let now = Date()
                let dfm = DateFormatter()
                dfm.dateFormat = "yyyyMMddHHmmss"
                let nowStr = dfm.string(from: now)
                var urlStr = String(format: "https://route.showapi.com/213-1?keyword=%@&page=%d&showapi_appid=30499&showapi_timestamp=%@&showapi_sign=bd7693a43b504b91ab93edd5d7f1518e", keyword!, nextPage!, nowStr)
                urlStr = urlStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                url = URL(string: urlStr)
                loadMusicList()
            }
        }
    }
    
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let vc = segue.destination as! PlayMusicViewController
        if isSearch == false {
            vc.url = URL(string: ((dataArray?[sender as! Int] as! [String : AnyObject])["url"] as? String)!)
        }else{
            vc.url = URL(string: ((dataArray?[sender as! Int] as! [String : AnyObject])["m4a"] as? String)!)
        }
    }


}
