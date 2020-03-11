//
//  Comment.swift
//  Firebase-Demo
//
//  Created by Maitree Bain on 3/11/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation
import Firebase

struct Comment {
    let commentDate: Timestamp
    let commentedBy: String
    let itemID: String
    let itemName: String
    let sellerName: String
    let text: String
}

extension Comment {
    init(_ dictionary: [String: Any]){
        //we uset this initializer when converting a snapshot firebase data object ot our Swift model (Comment)
        self.commentDate = dictionary["commentDate"] as? Timestamp ?? Timestamp(date: Date())
        self.commentedBy = dictionary["commentedBy"] as? String ?? "no commentedBy name"
        self.itemID = dictionary["itemID"] as? String ?? "no itemID"
        self.itemName = dictionary["itemName"] as? String ?? "no itemName"
        self.sellerName = dictionary["sellerName"] as? String ?? "no sellerName"
        self.text = dictionary["text"] as? String ?? "no text"
    }
}
