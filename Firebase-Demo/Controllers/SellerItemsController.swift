//
//  SellerItemsController.swift
//  Firebase-Demo
//
//  Created by Maitree Bain on 3/13/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseFirestore

class SellerItemsController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var item: Item
    
    private var items = [Item]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    //coder is needed if we are coming from a storyboard
    init?(coder: NSCoder, item: Item) {
        self.item = item
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        fetchItems()
        fetchUserImg()
        navigationItem.title = "@\(item.sellerName)"
    }
    
    private func fetchItems() {
        //refactor DatabaseService and StorageService as a singleton
        // DatabaseSerivce {
        /*
         private init() {}
         statis let shared = DatabaseService
         */
        //}
        //e.g DatabaseService.shared.function...
        
        DatabaseService().fetchUserItems(userID: item.sellerID) { [weak self] (result) in
            
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Failed to fetch items", message: "\(error.localizedDescription)")
                }
            case .success(let items):
                self?.items = items
            }
        }
    }
    
    private func fetchUserImg() {
        
        Firestore.firestore().collection(DatabaseService.usersCollection).document(item.sellerID).getDocument { (snapshot, error) in
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error fetching user", message: "\(error.localizedDescription)")
                }
            } else if let snapshot = snapshot {
                //TODO: could be refactored to a User model
                if let photoURL = snapshot.data()?["photoURL"] as? String {
                    DispatchQueue.main.async {
                        self.tableView.tableHeaderView = HeaderView(imageURL: photoURL)
                    }
                }
            }
            
        }
    }
    
    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "ItemCell", bundle: nil), forCellReuseIdentifier: "itemCell")
    }

}

extension SellerItemsController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ItemCell else {
            fatalError("Could not downcast to ItemCell")
        }
        
        let item = items[indexPath.row]
        cell.configureCell(for: item)
        
        return cell
        
    }
}

extension SellerItemsController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}
