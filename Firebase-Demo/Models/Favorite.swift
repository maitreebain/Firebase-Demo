//
//  Favorite.swift
//  Firebase-Demo
//
//  Created by Maitree Bain on 3/13/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation
import Firebase

struct Favorite {
    let itemName: String
    let favoritedDate: Timestamp
    let imageURL: String
    let itemID: String
    let price: Double
    let sellerID: String
    let sellerName: String
}

extension Favorite {
    //failable initializer
    //all properties need to exist in order for the object to get created
    //if you're sure all the data will exist, then use a failable initializer
    init?(_ dictionary: [String: Any]) {
        guard let itemName = dictionary["itemName"] as? String,
            let favoritedDate = dictionary["favoritedDate"] as? Timestamp,
            let imageURL = dictionary["imageURL"] as? String,
            let itemID = dictionary["itemID"] as? String,
            let price = dictionary["price"] as? Double,
            let sellerID = dictionary["sellerID"] as? String,
        let sellerName = dictionary["sellerName"] as? String
        else {
                return nil
        }
        self.itemName = itemName
        self.favoritedDate = favoritedDate
        self.imageURL = imageURL
        self.itemID = itemID
        self.price = price
        self.sellerID = sellerID
        self.sellerName = sellerName
    }
}
