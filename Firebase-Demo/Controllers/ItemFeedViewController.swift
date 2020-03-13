//
//  ItemFeedViewController.swift
//  Firebase-Demo
//
//  Created by Maitree Bain on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class ItemFeedViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var listener: ListenerRegistration?
    private var databaseService = DatabaseService()
    
    private var items = [Item]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "ItemCell", bundle: nil), forCellReuseIdentifier: "itemCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        listener = Firestore.firestore().collection(DatabaseService.itemsCollection).addSnapshotListener({ [weak self] (snapshot, error) in
            
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Firestore Error", message: "\(error.localizedDescription)")
                }
            } else if let snapshot = snapshot {
                let items = snapshot.documents.map { Item($0.data()) }
                self?.items = items.sorted(by: { $0.listedDate.dateValue() > $1.listedDate.dateValue() })
            }
        })
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        listener?.remove() // no longer are we listening for changes from Firebase
    }
}

extension ItemFeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ItemCell else {
            fatalError("could not downcast to ItemCell")
        }
        
        let item = items[indexPath.row]
        cell.configureCell(for: item)
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //perform deletion on item
            let item = items[indexPath.row]
            databaseService.deletePosting(item: item) { [weak self] (result) in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Deletion error", message: "\(error.localizedDescription)")
                    }
                case .success:
                    print("deleted successfully")
                }
                
            }
        }
    }
    
    //user who created is the only one able to delete the item
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let item = items[indexPath.row]
        guard let user = Auth.auth().currentUser else { return false }
        
        if item.sellerID != user.uid {
            return false
        } else {
            return true
        }
        
    }
    
    //that's not enough to only prevent accidental deletion on the client, we need to protect the database as well, we will do so using "Security Rules"
}

extension ItemFeedViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        let storyboard = UIStoryboard(name: "MainView", bundle: nil)
        let itemDetailVC = storyboard.instantiateViewController(identifier: "ItemDetailController") { (coder)
            in
            
            return ItemDetailController(coder: coder, item: item)
        }
        
        navigationController?.pushViewController(itemDetailVC, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}

extension ItemFeedViewController: ItemCellDelegate {
    func didSelectSellerName(_ itemCell: ItemCell, item: Item) {
        let storyboard = UIStoryboard(name: "MainView", bundle: nil)
        let sellerItemsVC = storyboard.instantiateViewController(identifier: "SellerItemsController") { (coder) in
            return SellerItemsController(coder: coder, item: item)
        }
        
        navigationController?.pushViewController(sellerItemsVC, animated: true)
    }
}
