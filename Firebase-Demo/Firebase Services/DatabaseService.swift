//
//  DatabaseService.swift
//  Firebase-Demo
//
//  Created by Maitree Bain on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class DatabaseService {
    
    static let itemsCollection = "items" // collections
    
    //let's get a reference to the Firebase Firestore database
    
    private let db = Firestore.firestore()
    //refers to firestore database
    
    public func createItem(itemName: String, price: Double, category: Category, displayName: String, completion: @escaping (Result<String, Error>) -> ()) {
        //"sellerID" - user.uuID
        guard let user = Auth.auth().currentUser else { return }
        
        //generate a document from the "items" collection
        let documentRef = db.collection(DatabaseService.itemsCollection).document()
        
        //create a document in our "items" collection
        //property names from model is going to be our key names
        db.collection(DatabaseService.itemsCollection).document(documentRef.documentID).setData([
            "itemName": itemName,
            "price": price,
            "itemID": documentRef.documentID,
            "listedDate": Timestamp(date: Date()),
            "sellerName": displayName,
            "sellerID": user.uid,
            "categoryName": category.name,
        ]) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(documentRef.documentID))
            }
        }
        
    }
    
}
