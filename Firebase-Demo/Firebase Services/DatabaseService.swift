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
    static let usersCollection = "users"
    static let commentsCollection = "comments" // sub-collection on an item document
    static let favoritesCollection = "favorites" // sub-collection on a user document
    
    //review - firebase firestore hierachy
    // top lvl
    // collection -> document -> collection -> document -> collection -> document ->...
    
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
    
    public func createDatabaseUser(authDataResult: AuthDataResult, completion: @escaping (Result<Bool, Error>) -> ()) {
        
        guard let email = authDataResult.user.email else { return }
        
        db.collection(DatabaseService.usersCollection).document(authDataResult.user.uid).setData(
            [
                "email" : email,
                "createdDate": Timestamp(date: Date()),
                "userID": authDataResult.user.uid
            ])
        { (error) in
            
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
            
        }
    }
    
    public func updateDatabaseUser(displayName: String, photoURL: String, completion: @escaping (Result<Bool, Error>) -> ()) {
        
        guard let user = Auth.auth().currentUser else { return }
        
        db.collection(DatabaseService.usersCollection).document(user.uid).updateData([
            "photoURL" : photoURL,
            "displayName": displayName
        ]) { (error) in
            
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
    
    public func postComment(item: Item, comment: String, completion: @escaping (Result<Bool, Error>) -> ()) {
        guard let user = Auth.auth().currentUser, let displayName = user.displayName else {
            print("no display name")
            return
        }
        
        //creating document here
        let docRef = db.collection(DatabaseService.itemsCollection).document(item.itemID).collection(DatabaseService.commentsCollection).document()
        
        //using document from above to write to firebase
        db.collection(DatabaseService.itemsCollection).document(item.itemID).collection(DatabaseService.commentsCollection).document(docRef.documentID).setData([
            "text" : comment,
            "createdDate": Timestamp(date: Date()),
            "itemName": item.itemName,
            "itemID": item.itemID,
            "sellerName": item.sellerName,
            "commentedBy": displayName
        ]) { (error) in
            
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
    
    public func addToFavorites(item: Item, completion: @escaping (Result<Bool, Error>) -> ()) {
        guard let user = Auth.auth().currentUser else { return }
        db.collection(DatabaseService.usersCollection).document(user.uid).collection(DatabaseService.favoritesCollection).document(item.itemID).setData([
            "itemName" : item.itemName,
            "price": item.price,
            "imageURL": item.imageURL,
            "favoritedDate": Timestamp(date: Date()),
            "itemID": item.itemID,
            "sellerName": item.sellerName,
            "sellerID": item.sellerID
        ]) { (error) in
            
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
            
        }
    }
    
    public func removeFromFavorites(item: Item, completion: @escaping (Result<Bool, Error>) -> ()) {
        guard let user = Auth.auth().currentUser else { return }
        db.collection(DatabaseService.usersCollection).document(user.uid).collection(DatabaseService.favoritesCollection).document(item.itemID).delete { (error) in
            
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
    
    public func isItemInFavorites(item: Item, completion: @escaping (Result<Bool, Error>) -> ()) {
        guard let user = Auth.auth().currentUser else { return }
        
        //in firebase we use the "where" to query(search) a collection
        
        //addSnapshotListener - continues to listen for modifications to a collection
        //getDocuments - fetches documents ONLY once
        db.collection(DatabaseService.usersCollection).document(user.uid).collection(DatabaseService.favoritesCollection).whereField("itemID", isEqualTo: item.itemID).getDocuments { (snapshot, error) in
            
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                let count = snapshot.documents.count
                if count > 0 { // check if we have documents
                    completion(.success(true))
                } else {
                    completion(.success(false))
                }
            }
            
        }
    }
    
    public func fetchUserItems(userID: String, completion: @escaping (Result<[Item], Error>) -> ()) {
        db.collection(DatabaseService.itemsCollection).whereField(Constants.selledID, isEqualTo: userID).getDocuments { (snapshot, error) in
            
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                let items = snapshot.documents.map { Item($0.data()) }
                completion(.success(items))
            }
        }
    }
    
    public func fetchFavorites(completion: @escaping (Result<[Favorite], Error>) -> ()) {
        //access users collection -> userID (document) -> favorites
        guard let user = Auth.auth().currentUser else { return }
        
        db.collection(DatabaseService.usersCollection).document(user.uid).collection(DatabaseService.favoritesCollection).getDocuments { (snapshot, error) in
            
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                let favorites = snapshot.documents.compactMap { Favorite($0.data())}
                completion(.success(favorites))
            }
            //compactMap removes nil values
        }
        
    }
    
    public func deletePosting(item: Item, completion: @escaping (Result<Bool, Error>) -> ()) {
        db.collection(DatabaseService.itemsCollection).document(item.itemID).delete { (error) in
            
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
    
}
