//
//  StorageService.swift
//  Firebase-Demo
//
//  Created by Maitree Bain on 3/4/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation
import FirebaseStorage

class StorageService {
    
    //in our app we will be uploading a photo to Storage in two places: 1. ProfileViewController and 2. CreateItemViewController
    
    //we will be creating two different buckets of folders 1. UserProfilePhotos/user.uid 2. ItemsPhotos/item.itemID
    
    //let's create a reference to the Firebase storage
    private let storageRef = Storage.storage().reference()
    
    //default parameters in Swift e.g userID: String? = nil
    public func uploadPhoto(userID: String? = nil, itemID: String? = nil, image: UIImage, completion: @escaping (Result<URL,Error>) -> ()){
        
        //1. convert UIImage to Data because this is the object we are posting to Firebase Storage
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return }//1.0 is full compression
        
        //we need to establish which bucket of collection or folder we will be saving the folder to
        var photoReference: StorageReference!
        
        if let userID = userID { //coming from ProfileViewController
            photoReference = storageRef.child("UserProfilePhotos/\(userID).jpg")
        } else if let itemID = itemID { //coming from CreateItemViewController
            photoReference = storageRef.child("ItemPhotos/\(itemID).jpg")
        }
        
        // configure metadata for the object being uploaded
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg" // MIME type
        
        let _ = photoReference.putData(imageData, metadata: metadata) { (metadata, error) in
            
            if let error = error {
                completion(.failure(error))
            } else if let _ = metadata {
                photoReference.downloadURL { (url, error) in //this url is the location of the photo
                    
                    if let error = error {
                        completion(.failure(error))
                    } else if let url = url {
                        completion(.success(url))
                    }
                    
                }
            }
            
        }
        
    }
    
}
