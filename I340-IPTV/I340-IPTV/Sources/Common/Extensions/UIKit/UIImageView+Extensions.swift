//
//  UIImageView+Extensions.swift
//  I340_IPTV
//
//  Created by Mac mini M2 on 26/4/25.
//

import Kingfisher

extension UIImageView {
    func setImage(with resource: Resource?,
                  placeholder: Placeholder? = nil,
                  onSuccess: (() -> Void)? = nil,
                  onError: (() -> Void)? = nil) {

        kf.indicatorType = .activity
        let resolvedPlaceholder: Placeholder?
        if let placeholder {
            resolvedPlaceholder = placeholder
        } else {
            resolvedPlaceholder = UIImage(named: "ic_unknown") ?? UIImage(systemName: "photo")
        }
        
        kf.setImage(with: resource,
                    placeholder: resolvedPlaceholder,
                    options: [.transition(.fade(1)),
                              .cacheOriginalImage],
                    completionHandler: { result in
                        switch result {
                        case .success:

                            onSuccess?()
                        case .failure:
                            onError?()
                        }
                    })
    }
    
    func cancelImageDownload() {
        kf.cancelDownloadTask()
    }
}
