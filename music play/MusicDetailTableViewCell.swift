//
//  MusicDetailTableViewCell.swift
//  music play
//
//  Created by xinyue-0 on 2017/1/10.
//  Copyright © 2017年 xinyue-0. All rights reserved.
//  

import UIKit

class MusicDetailTableViewCell: UITableViewCell {
    
    @IBOutlet var songnameLabel: UILabel!
    @IBOutlet var singernameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
