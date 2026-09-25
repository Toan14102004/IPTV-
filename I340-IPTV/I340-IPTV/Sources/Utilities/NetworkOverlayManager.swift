//
//  NetworkOverlayManager.swift
//  I340_IPTV
//
//  Created by Mac mini M2 on 03/01/2025.
//

import Foundation
import Network
import RxSwift
import SwiftUI

class NetworkOverlayManager {
    static let shared = NetworkOverlayManager()
    private var noConnectionWindow: UIWindow?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    let isConnectedSubject = BehaviorSubject<Bool>(value: true)
    var isConnected: Bool = true
    private let disposeBag = DisposeBag()
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            if path.status == .satisfied {
                self.checkRealInternet()
            } else {
                self.isConnectedSubject.onNext(false)
                self.isConnected = false
            }
        }
        monitor.start(queue: queue)
        observeNetworkStatus()
    }
    
    private func observeNetworkStatus() {
        self.isConnectedSubject
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isConnected in
                guard let self = self else { return }
                if isConnected {
                    self.hideNoConnectionView()
                } else {
                    self.showNoConnectionView()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func checkRealInternet() {
        guard let url = URL(string: "https://www.google.com/generate_204") else {
            isConnectedSubject.onNext(false)
            self.isConnected = false
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5 // time out check internet
        
        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            guard let self = self else { return }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                self.isConnectedSubject.onNext(true)
                self.isConnected = true
            } else {
                self.isConnectedSubject.onNext(false)
                self.isConnected = false
            }
        }.resume()
    }
    
    private func showNoConnectionView() {
        guard noConnectionWindow == nil else { return }
        noConnectionWindow = UIWindow(frame: UIScreen.main.bounds)
        noConnectionWindow?.windowLevel = .alert + 1
        noConnectionWindow?.backgroundColor = .clear
        noConnectionWindow?.rootViewController = UIHostingController(rootView: NoConnectionView())
        noConnectionWindow?.makeKeyAndVisible()
    }
    
    private func hideNoConnectionView() {
        guard let noConnectionWindow = noConnectionWindow else { return }
        UIView.animate(withDuration: 0.3, animations: {
            noConnectionWindow.alpha = 0
        }, completion: { _ in
            noConnectionWindow.isHidden = true
            self.noConnectionWindow = nil
        })
    }
}
