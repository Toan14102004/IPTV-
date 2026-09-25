//
//  BaseViewModel.swift
//  I340_IPTV
//
//  Created by Toan Nguyen on 20/11/24.
//

import Combine
import Foundation
import SwiftUI

protocol BaseViewModel: ObservableObject {
    associatedtype CoordinatorType: BaseCoordinator

    var coordinator: CoordinatorType { get }
}
