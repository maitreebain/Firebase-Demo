//
//  ItemDetailController.swift
//  Firebase-Demo
//
//  Created by Maitree Bain on 3/11/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ItemDetailController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var containerBottomConst: NSLayoutConstraint!
    @IBOutlet weak var commentTextField: UITextField!

    private var item: Item
    private var databaseServices = DatabaseService()
    private var listener: ListenerRegistration?
    
    private var comments = [Comment]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private lazy var dateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, h:mm a"
        return formatter
    }()
    
    private var originalConstraintValue: CGFloat = 0
    
    init?(coder: NSCoder, item: Item) {
        self.item = item
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var tapGesture: UITapGestureRecognizer = {
       let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(dismissKeyboard))
        return gesture
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = item.itemName
        
        commentTextField.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = HeaderView(imageURL: item.imageURL)
        originalConstraintValue = containerBottomConst.constant
        registerKeyboardNotifications()
        view.addGestureRecognizer(tapGesture)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        registerKeyboardNotifications()
        
        listener = Firestore.firestore().collection(DatabaseService.itemsCollection).document(item.itemID).collection(DatabaseService.commentsCollection).addSnapshotListener({ [weak self] (snapshot, error) in
            
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Try Again", message: "\(error.localizedDescription)")
                }
            } else if let snapshot = snapshot {
            //create comments using dictionary initializer from the comment model
                let comments = snapshot.documents.map { Comment($0.data())}
                self?.comments = comments.sorted( by: { $0.commentDate.dateValue() < $1.commentDate.dateValue() })
                //maybe fix the sorted?
            } else {
                
            }
            
        })
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        unregisterKeyboardNotifications()
        listener?.remove()
    }

    @IBAction func sendButtonPressed(_ sender: UIButton) {
    dismissKeyboard()
        //TODO: add comment on Firebase item document
        //getting ready to post to fire base
        guard let commentText = commentTextField.text, !commentText.isEmpty else {
            self.showAlert(title: "Missing Fields", message: "Comment required")
            return
        }
        
        // post to firebase
        postComment(text: commentText)
    }
    
    private func postComment(text: String) {
        databaseServices.postComment(item: item, comment: text) { [weak self] (result) in
            
            switch result{
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Comment Failure", message: "Could not post comment: \(error.localizedDescription)")
                }
            case .success:
                DispatchQueue.main.async {
                    self?.showAlert(title: "Success", message: "Comment posted!")
                }
            }
        }
    }
    
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?["UIKeyboardBoundsUserInfoKey"] as? CGRect else {
            return
        }
        
        //adjust the container bottom constraint
        containerBottomConst.constant = -(keyboardFrame.height - view.safeAreaInsets.bottom)
    }
    
    @objc private func keyboardWillHide(_ notification: Notification){
        dismissKeyboard()
    }
    
    @objc private func dismissKeyboard() {
        containerBottomConst.constant = originalConstraintValue
        commentTextField.resignFirstResponder()
    }
    
    
    @IBAction func favoriteButtonPressed(_ sender: UIBarButtonItem) {
        databaseServices.addToFavorites(item: item) { [weak self] (result) in
            
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Favoriting failed", message: "\(error.localizedDescription)")
                }
            case .success:
                self?.showAlert(title: "Item added", message: nil)
            }
        }
    }
    
}

extension ItemDetailController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath)
        
        let comment = comments[indexPath.row]
        let dateString = dateFormatter.string(from: comment.commentDate.dateValue())
        cell.textLabel?.text = comment.text
        cell.detailTextLabel?.text = "@\(comment.commentedBy) - \(dateString)"
        
        return cell
    }
    
    
}

extension ItemDetailController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
}

