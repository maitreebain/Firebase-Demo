//
//  CreateItemViewController.swift
//  Firebase-Demo
//
//  Created by Maitree Bain on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CreateItemViewController: UIViewController {
    
    @IBOutlet weak var itemNameTextField: UITextField!
    @IBOutlet weak var itemPriceTextField: UITextField!
    @IBOutlet weak var itemImageView: UIImageView!
    
    private var category: Category
    
    private let dbService = DatabaseService()
    private let storageService = StorageService()
    
    private lazy var imagePickerController: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self //conform to UIImagePickerDelegate and UINavigationControllerDelegate
        return picker
    }()
    
    private lazy var longPressGesture: UILongPressGestureRecognizer = {
       let gesture = UILongPressGestureRecognizer()
        gesture.addTarget(self, action: #selector(showPhotoOptions))
        return gesture
    }()
    
    private var selectedImage: UIImage? {
        didSet{
            itemImageView.image = selectedImage
        }
    }
    
    init?(coder: NSCoder, category: Category){
        self.category = category
        super.init(coder: coder)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = category.name
        //add long press
        itemImageView.isUserInteractionEnabled = true
        itemImageView.addGestureRecognizer(longPressGesture)
    }
    
    
    @objc private func showPhotoOptions() {
        let alertController = UIAlertController(title: "Choose Photo Option", message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (alertAction) in
            self.imagePickerController.sourceType = .camera
            self.present(self.imagePickerController, animated: true)
        }
        let photoLibrary = UIAlertAction(title: "Photo Library", style: .default) { (alertAction) in
            self.imagePickerController.sourceType = .photoLibrary
            self.present(self.imagePickerController, animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(cameraAction)
        }
        alertController.addAction(photoLibrary)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    
        
    }
    
    @IBAction func postItemButtonPressed(_ sender: UIBarButtonItem) {
        //dismiss(animated: true)
        guard let itemName = itemNameTextField.text,
            !itemName.isEmpty,
            let priceText = itemPriceTextField.text,
            !priceText.isEmpty,
            let price = Double(priceText),
        let image = selectedImage else {
                showAlert(title: "Missing Fields", message: "All fields are required along with a photo.")
                return
        }
        
        //resize image before uploading to storage
        let resizedImage = UIImage.resizeImage(originalImage: image, rect: itemImageView.bounds)
        
        guard let displayName = Auth.auth().currentUser?.displayName else {
            DispatchQueue.main.async {
                self.showAlert(title: "Incomplete Profile", message: "Please complete your Profile")
            }
            return
        }
        
        dbService.createItem(itemName: itemName, price: price, category: category, displayName: displayName) { [weak self] (result) in
            
            switch result {
            case .failure (let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error creating item", message: "Something went wrong: \(error.localizedDescription)")
                }
            case .success(let documentID):
                //TODO: upload photo to storage
                self?.uploadPhoto(image: resizedImage, documentID: documentID)
            }
        }
    }
    
    private func uploadPhoto(image: UIImage, documentID: String) {
        storageService.uploadPhoto(itemID: documentID, image: image) { [weak self] (result) in
            
            switch result{
            case .failure(let error):
            DispatchQueue.main.async {
                self?.showAlert(title: "Error uploading photo", message: "\(error.localizedDescription)")
            }
            case .success(let url):
                self?.updateItemImageURL(url: url, documentID: documentID)
            }
        }
    }
    
    private func updateItemImageURL(url: URL, documentID: String) {
        //update an existing document on Firebase
        //basically creating another item on model on firebase storage - "imageURL"
        Firestore.firestore().collection(DatabaseService.itemsCollection).document(documentID).updateData(["imageURL" : url.absoluteString]) { [weak self] (error) in
            
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Fail to update item", message: "\(error.localizedDescription)")
                }
            } else {
                print("Item image update success")
                DispatchQueue.main.async {
                    self?.dismiss(animated: true)
                }
            }
        }
    }
    
}

extension CreateItemViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            fatalError("could not attain original image")
        }
        selectedImage = image
        dismiss(animated: true)
    }
}
