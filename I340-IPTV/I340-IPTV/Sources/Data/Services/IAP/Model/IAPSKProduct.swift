//
//  SKU.swift
//  Mirror Screen
//
//  Created by Nguyen Van Nhon on 3/5/20.
//  Copyright © 2020 Foxcode Studio. All rights reserved.
//

import Foundation

enum ProductType: Equatable {
    case autoRenewable
    case nonRenewing
}

struct IAPSKProduct :Hashable {
    var name: String
    var id: String
    var type: ProductType
    var key: Periods
    var isComsumable: Bool = false
}
