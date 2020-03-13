//
//  Item.swift
//  Firebase-Demo
//
//  Created by Maitree Bain on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation
import Firebase

struct Item {
    let itemName: String
    let price: Double
    let itemID: String
    let listedDate: Timestamp
    let sellerName: String
    let sellerID: String
    let categoryName: String
    //image
    let imageURL: String
}

extension Item {
    init(_ dictionary: [String: Any]) {
        self.itemName = dictionary["itemName"] as? String ?? "no item name"
        self.price = dictionary["price"] as? Double ?? 0.0
        self.itemID = dictionary["itemID"] as? String ?? "no item id"
        self.listedDate = dictionary["listedDate"] as? Timestamp ?? Timestamp(date: Date())
        self.sellerName = dictionary["sellerName"] as? String ?? "no seller name"
        self.sellerID = dictionary["sellerID"] as? String ?? "no seller id"
        self.categoryName = dictionary["categoryName"] as? String ?? "no category name"
        self.imageURL = dictionary["imageURL"] as? String ?? "no image url"
    }
}
