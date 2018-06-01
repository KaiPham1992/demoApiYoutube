//
//  VideoCell.swift
//  youtubetest
//
//  Created by Kai Pham on 5/30/18.
//  Copyright © 2018 Dhanashree Inc. All rights reserved.
//

import UIKit
import SDWebImage

class VideoCell: UITableViewCell {

    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var lbTitle: UILabel!
    
    var video: Video? {
        didSet{
            guard let _video = video, let urlStr = _video.url,  let _url = URL(string: urlStr) else { return }
            
            imgIcon.sd_setImage(with: _url, completed: nil)
            lbTitle.text = _video.title
            
            self.backgroundColor = _video.isSelected == true ? .yellow: .white
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
    
    
}
