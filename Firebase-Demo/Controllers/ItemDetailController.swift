//
//  ItemDetailController.swift
//  Firebase-Demo
//
//  Created by Maitree Bain on 3/11/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit

class ItemDetailController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var containerBottomConst: NSLayoutConstraint!
    @IBOutlet weak var commentTextField: UITextField!

    private var item: Item
    
    private var originalConstraintValue: CGFloat = 0
    
    init?(coder: NSCoder, item: Item) {
        self.item = item
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = item.itemName
        
        tableView.tableHeaderView = HeaderView(imageURL: item.imageURL)
        originalConstraintValue = containerBottomConst.constant
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        registerKeyboardNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        unregisterKeyboardNotifications()
    }

    @IBAction func sendButtonPressed(_ sender: UIButton) {
    
    }
    
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        print(notification.userInfo ?? "")
        guard let keyboardFrame = notification.userInfo?["UIKeyboardBoundsUserInfoKey"] as? CGRect else {
            return
        }
        
    }
    
    @objc private func keyboardWillHide(_ notification: Notification){
        
    }
    
    
    
}
