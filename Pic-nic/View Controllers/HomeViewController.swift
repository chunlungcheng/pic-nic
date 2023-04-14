//
//  HomeViewController.swift
//  Pic-nic
//
//  Created by Isaiah Suarez on 3/4/23.
//

import UIKit
import Firebase
import FirebaseFirestore

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableview: UITableView!
    
    var datasource = [Post]()
    let db = Firestore.firestore()
    
    /// Set to true if user is not logged in when home screen is presented
    var needsToDownload = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.delegate = self
        tableview.dataSource = self
        downloadPosts()
    }
    
    func downloadPosts() {
        let postsRef = db.collection("locations").document("Austin").collection("posts") // DO NOT CHANGE
        postsRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            var posts = [Post]()
            
            for document in documents {
                let id = document.documentID
                let data = document.data()
                let date = data["date"] as? String ?? ""
                let imageData = data["imageData"] as? Data
                let location = data["location"] as? String ?? ""
                let userID = data["userID"] as? String ?? ""
                
                if let imageData = imageData, let image = UIImage(data: imageData) {
                    posts.append(Post(date: date, image: image, location: location, userID: userID))
                }
            }
            
            // Do something with the users array
            print(posts)
            self.datasource = posts
            self.tableview.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkIfUserIsLoggedIn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("We back")
        if needsToDownload {
            downloadPosts()
            needsToDownload = false
        }
    }
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            if let loginVC = storyboard.instantiateViewController(withIdentifier: LoginViewController.identifier) as? LoginViewController {
                loginVC.delegate = self
                needsToDownload = true
                present(loginVC, animated: true)
            }
        } else {
            print(Auth.auth().currentUser?.email)
        }
    }
}

extension HomeViewController: LoginViewControllerDelegate {
    func loginViewControllerLoggedInSuccessfully(loginViewController: UIViewController?) {
        loginViewController?.dismiss(animated: true)
    }
}
extension HomeViewController: UITableViewDelegate {
    
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.reuseIdentifer, for: indexPath) as! PostCell
        let post = datasource[indexPath.row]
        cell.nameLabel.text = "Name"
        cell.locationLabel.text = "Location"
        cell.postImageView.image = post.image
//        cell.profileImageView.image = UIImage(named: post.5)
        cell.timeLabel.text = "time"
        cell.likesLabel.text = "likes"
        return cell
    }
    
}
