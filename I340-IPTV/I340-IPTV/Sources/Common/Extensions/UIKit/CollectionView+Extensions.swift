//
//  UITableView+UICollectionView+Extensions.swift
//  FireStick-iOS
//
//  Created by HaoLK on 28/12/2020.
//  Copyright © 2020 FoxCode. All rights reserved.
//

import UIKit

extension UICollectionView {
    func registerCell<T>(ofType type: T.Type) {
        let typeName = String(describing: type)
        self.register(UINib(nibName: typeName, bundle: nil), forCellWithReuseIdentifier: typeName)
    }
}

extension UICollectionViewCell {
    static var identifier: String {
        return String(describing: self)
    }
}

extension UICollectionView {
    func setEmptyMessage(_ message: String = "no_items_to_show".localized) {
        let messageLabel = UILabel(frame: bounds)
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        messageLabel.sizeToFit()
        
        backgroundView = messageLabel
    }
    
    func hideEmptyMessage() {
        backgroundView = nil
    }
}
