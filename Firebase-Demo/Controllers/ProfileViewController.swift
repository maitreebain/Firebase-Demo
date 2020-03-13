//
//  ProfileViewController.swift
//  Firebase-Demo
//
//  Created by Maitree Bain on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseAuth
import Kingfisher

enum ViewState {
    case myItems
    case favorites
}

class ProfileViewController: UIViewController {
    
    //add signout button
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private lazy var imagePickerController: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        return imagePicker
    }()
    
    private var refreshControl: UIRefreshControl!
    
    private var selectedImage: UIImage? {
        didSet{
            profileImageView.image = selectedImage
        }
    }
    
    private let storageService = StorageService()
    private var databaseService = DatabaseService()
    
    private var viewState: ViewState = .myItems {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private var favorites = [Favorite]() {
        didSet{
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private var myItems = [Item]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayNameTextField.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        updateUI()
        tableView.register(UINib(nibName: "ItemCell", bundle: nil), forCellReuseIdentifier: "itemCell")
        loadData()
        refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(loadData), for: .valueChanged)
    }
    
    private func updateUI() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        emailLabel.text = user.email
        displayNameTextField.text = user.displayName
        //user.displayName
        //user.email
        //user.phoneNumber
        //user.photoURL
        
        profileImageView.kf.setImage(with: user.photoURL)
        //resource!!
        
    }
    
    @objc private func loadData() {
        fetchItems()
        fetchFavorites()
    }
    
    @objc private func fetchItems() {
        guard let user = Auth.auth().currentUser else {
            refreshControl.endRefreshing()
            return }
        
        databaseService.fetchUserItems(userID: user.uid) { [weak self] (result) in
            
            switch result {
            case .failure(let error):
                self?.showAlert(title: "Fetching error", message: "\(error.localizedDescription)")
            case .success(let items):
                self?.myItems = items
            }
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
            }
        }
    }
    
    @objc private func fetchFavorites() {
        databaseService.fetchFavorites { [weak self] (result) in
            
            switch result {
            case .failure(let error):
                self?.showAlert(title: "Fetching favorites error", message: "\(error.localizedDescription)")
            case .success(let favorites):
                self?.favorites = favorites
            }
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
            }
        }
    }
    
    private func updateDatabaseUser(displayName: String, photoURL: String) {
        databaseService.updateDatabaseUser(displayName: displayName, photoURL: photoURL) { (result) in
            
            switch result {
            case .failure(let error):
                print("bleep: \(error)")
            case .success:
                print("blop")
            }
        }
    }
    
    
    @IBAction func updateProfileButtonPressed(_ sender: UIButton) {
        
        guard let displayName = displayNameTextField.text, !displayName.isEmpty, let selectedImage = selectedImage else {
            print("missing fields")
            return
        }
        //resize image before uploading to Firebase
        let resizedImage = UIImage.resizeImage(originalImage: selectedImage, rect: profileImageView.bounds)
        
        print("orig \(selectedImage.size) not orig \(resizedImage)")
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        storageService.uploadPhoto(userID: user.uid, image: resizedImage) { [weak self] (result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error uploading photo", message: "\(error.localizedDescription)")
                }
            case .success(let url):
                self?.updateDatabaseUser(displayName: displayName, photoURL: url.absoluteString)
                //TODO: refactor into its own function
                let request = Auth.auth().currentUser?.createProfileChangeRequest()
                request?.displayName = displayName
                request?.photoURL = url
                //get kingfisher to update image in updateui
                request?.commitChanges(completion: { [weak self] error in
                    
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Error updating profile", message: "Error changing profile error: \(error.localizedDescription)")
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Profile Update", message: "Profile successfully updated")
                        }
                    }
                })
            }
        }
    }
    
    @IBAction func editProfilePhotoButtonPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Choose photo option", message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) {
            alertAction in
            self.imagePickerController.sourceType = .camera
            self.present(self.imagePickerController, animated: true)
        }
        let photolibraryAction = UIAlertAction(title: "Photo Library", style: .default) {
            alertAction in
            self.imagePickerController.sourceType = .photoLibrary
            self.present(self.imagePickerController, animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(cameraAction)
        }
        alertController.addAction(photolibraryAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    @IBAction func signOutButtonPressed(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            UIViewController.showViewController(storyboardName: "LoginView", viewControllerID: "LoginViewController")
        } catch {
            DispatchQueue.main.async {
                self.showAlert(title: "Error signing out", message: "\(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func segmentedControlPressed(_ sender: UISegmentedControl) {
        //toggle current viewState
        
        switch sender.selectedSegmentIndex {
        case 0:
            viewState = .myItems
            
        case 1:
            viewState = .favorites
        default:
            break
        }
        
    }
    
}

extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewState == .myItems {
            return myItems.count
        } else {
            return favorites.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ItemCell else {
            fatalError("could not downcast to itemCell")
        }
        
        if viewState == .myItems {
            let item = myItems[indexPath.row]
            cell.configureCell(for: item)
        } else {
            let favorite = favorites[indexPath.row]
            cell.configureFav(for: favorite)
        }
        
        return cell
    }
    
}

extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}

extension ProfileViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        selectedImage = image
        dismiss(animated: true)
    }
}
