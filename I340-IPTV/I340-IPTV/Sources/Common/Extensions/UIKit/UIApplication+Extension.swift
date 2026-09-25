//
//  UIApplication+Extension.swift
//  I340_IPTV
//
//  Created by Mac mini M2 on 03/01/2025.
//

import Foundation
import UIKit

extension UIApplication {

    static func openAppSettings(completion: @escaping (_ isSuccess: Bool) -> ()) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            completion(false)
            return
        }
        
        UIApplication.shared.open(url) { isSuccess in
            completion(isSuccess)
        }
    }
}
