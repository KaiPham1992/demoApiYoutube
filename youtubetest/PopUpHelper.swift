//
//  PopUpHelper.swift
//  youtubetest
//
//  Created by Kai Pham on 5/30/18.
//  Copyright © 2018 Dhanashree Inc. All rights reserved.
//

import UIKit

class PopUpHelper {
    class func showMessage(message: String, controller: UIViewController) {
        let alert = UIAlertController(title: "Notification", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil)
        
        alert.addAction(action)
        
        
        controller.present(alert, animated: true, completion: nil)
        
    }
}
