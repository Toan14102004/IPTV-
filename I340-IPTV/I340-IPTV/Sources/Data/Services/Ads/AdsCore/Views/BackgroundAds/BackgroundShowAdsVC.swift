//
//  BackgroundShowAdsVC.swift
//
//  Created by KietKoy on 2/8/24.
//  Copyright © 2024 Riley Testut. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BackgroundShowAdsVC: UIViewController {

    @IBOutlet weak var appIconImage: UIImageView!
    @IBOutlet weak var welcomeTextLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    
    var isComeback = false
    let bag = DisposeBag()
    
    init(isComeback: Bool = false) {
        self.isComeback = isComeback
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        appIconImage.image = Bundle.main.icon
        dismissButton.rx.tap
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                self.dismiss(animated: true)
                AppOpenAdUtils.shared.setShowingAdValue(false)
            }
            .disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configButtonDismiss()
        self.navigationController?.isNavigationBarHidden = true
        if isComeback {
            welcomeTextLabel.text = "welcome_back".localized
        } else {
            welcomeTextLabel.text = "loading_ads".localized + "..."
            appIconImage.isHidden = true
        }
    }
    
    func configButtonDismiss() {
        dismissButton.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            self.dismissButton.isHidden = false
        }
    }
}
