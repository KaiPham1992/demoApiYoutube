//
//  Thumbnail.swift
//  youtubetest
//
//  Created by Kai Pham on 5/30/18.
//  Copyright © 2018 Dhanashree Inc. All rights reserved.
//

import Foundation

class Video {
    var title: String?
    var url: String?
    var id: String?
    
    var isSelected: Bool = false
    
    init(id: String?, title: String?, url: String?) {
        self.title = title
        self.url = url
        self.id = id
    }
}
