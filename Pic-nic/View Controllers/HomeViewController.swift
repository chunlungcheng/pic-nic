//
//  HomeViewController.swift
//  Pic-nic
//
//  Created by Isaiah Suarez on 3/4/23.
//

import UIKit
import Firebase
import FirebaseFirestore

extension Notification.Name {
    static let updateTableView = Notification.Name("com.example.updateTableView")
}

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableview: UITableView!
    
    var datasource = [Post]()
    let refreshControl = UIRefreshControl()
    let db = Firestore.firestore()
    let commentSegue = "commentSeg"
    var postID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableview.delegate = self
        tableview.dataSource = self
        downloadPosts()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name.updateTableView, object: nil)
        tableview.allowsSelection = false
    }
    
    @objc func refreshData(_ sender: Any) {
        downloadPosts()
    }
    
    @objc func handleNotification(_ notification: Notification) {
        downloadPosts()
    }
    
    func downloadPosts() {
        let postsRef = db.collection("locations").document("Austin").collection("posts") // DO NOT CHANGE
        postsRef.addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            var posts = [Post]()
            
            for document in documents {
                let data = document.data()
                let date = data["date"] as? Timestamp
                let imageData = data["imageData"] as? Data
                let location = data["location"] as? String ?? ""
                let userID = data["userID"] as? String ?? ""
                let likeBy = data["likeBy"] as? [String] ?? [String]()
                let documentID = document.documentID
                if let imageData = imageData, let image = UIImage(data: imageData) {
                    posts.append(Post(date: date, image: image, location: location, userID: userID, documentID: documentID, likeBy: likeBy))
                }
            }
            self.datasource = posts
            self.datasource = self.datasource.sorted { $0.date?.dateValue() ?? Date.now  > $1.date?.dateValue() ?? Date.now}
            self.refreshControl.endRefreshing()
            self.tableview.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

extension HomeViewController: UITableViewDelegate {
    // do nothing?
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }
    
    @objc func handleDoubleTap(sender: UITapGestureRecognizer) {
        if let cell = sender.view?.superview as? PostCell {
            cell.animateHeart()
            // Like post if not already liked
            let indexPath = tableview.indexPath(for: cell)
            if !self.datasource[indexPath?.row ?? 0].likeBy.contains(Auth.auth().currentUser!.uid)  {
                likeButtonTapped(cell.likesButton)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.reuseIdentifer, for: indexPath) as! PostCell
        let post = datasource[indexPath.row]
        
        // Add double tap
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(sender:)))
        doubleTapGesture.numberOfTapsRequired = 2
        cell.contentView.addGestureRecognizer(doubleTapGesture)
        
        cell.locationLabel.text = "Austin"
        cell.postImageView.image = post.image
        
        // Add action to comment button
        cell.commentButton.addTarget(self, action: #selector(commentButtonTapped(_:)), for: .touchUpInside)
        
        // Add photo save
        if let image = cell.postImageView.image {
            if image.size.width == 0 || image.size.height == 0 {
                // Image is empty
                print("Image is empty")
                let errorAlert = UIAlertController(title: "Error", message: "Image is empty", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
            } else {
                // Image is not empty
                cell.savePhotoButton.addTarget(self, action: #selector(savePhotoButtonTapped(_:)), for: .touchUpInside)
            }
        }
        
        // Format date
        cell.timeLabel.text = dateString(date: post.date?.dateValue() ?? Date.now)
        
        // set likes
        cell.likesLabel.text = "\(post.likeBy.count) likes"
        
        if self.datasource[indexPath.row].likeBy.contains(Auth.auth().currentUser!.uid){
            cell.likesButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        } else {
            cell.likesButton.setImage(UIImage(systemName: "heart"), for: .normal)
        }
        cell.likesButton.addTarget(self, action: #selector(likeButtonTapped(_:)), for: .touchUpInside)
        
        // set three dot menu
        if Auth.auth().currentUser?.uid == post.userID {
            let deleteAction = UIAction(
                title: "Delete",
                image: UIImage(systemName: "trash"),
                attributes: .destructive) { action in
                    //delete the post from the firebase and table view
                    let postsRef = self.db.collection("locations").document("Austin").collection("posts").document(post.documentID)
                    postsRef.delete { error in
                        if let error = error {
                            print("Error deleting user data:", error.localizedDescription)
                            let errorAlert = UIAlertController(title: "Error", message: "Failed to delete the post. Please try again later.", preferredStyle: .alert)
                            errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(errorAlert, animated: true, completion: nil)
                        } else {
                            self.datasource.remove(at: indexPath.row)
                            self.tableview.reloadData()
                            print("Post deleted successfully.")
                        }
                    }
                }
            let editMenu = UIMenu(title: "", children: [deleteAction])
            cell.editButton.menu = editMenu
            cell.editButton.showsMenuAsPrimaryAction = true
        }
        
        guard post.userName == nil else {
            // We've previosuly downloaded this
            cell.profileImageView.image = post.profilePicture
            cell.nameLabel.text = post.userName
            return cell
        }
        
        // retrive the post from the Firebase and add it into the table view
        let docRef = db.collection("users").document(post.userID)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                // set name
                let firstname = data?["firstName"] as? String ?? ""
                let lastname = data?["lastName"] as? String ?? ""
                let name = firstname + " " + lastname
                // Find the post in the datasource
                guard let index = self.datasource.firstIndex(where: { $0.date == post.date }) else {
                    return
                }
                self.datasource[index].userName = name
                // set profile picture
                if let imageData = data?["profilePicture"] as? Data {
                    if imageData.count != 0 {
                        // Create an image from the data
                        let image = UIImage(data: imageData)
                        let resizedImage = image!.resizeImage(targetSize: CGSize(width: 40, height: 40))
                        // Use the image as needed
                        self.datasource[index].profilePicture = resizedImage
                    }
                    self.tableview.reloadRows(at: [indexPath], with: .automatic)
                } else {
                    print("Invalid image")
                }
            } else {
                print("Document does not exist")
            }
        }
      
        return cell
    }
    
    // like the post and update the number of likes on the Firestore and the post
    @objc func likeButtonTapped(_ sender: UIButton) {
        guard let cell = sender.superview?.superview?.superview as? PostCell, let indexPath = tableview.indexPath(for: cell) else { return }
        let post = datasource[indexPath.row]
        let currentUserID = Auth.auth().currentUser?.uid ?? ""
        let docRef = db.collection("locations").document("Austin").collection("posts").document(post.documentID)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                // Handle the user data here
                let likeBy = data?["likeBy"] as? [String] ?? [String]()
                let hasLiked = likeBy.contains(currentUserID)
                
                if hasLiked {
                    // Post was already liked by user, time to unlike it
                    let updatedLikeBy = post.likeBy.filter { $0 != currentUserID }
                    docRef.updateData(["likeBy": updatedLikeBy]) { error in
                        if let error = error {
                            print("Error updating document: \(error)")
                        } else {
                            self.datasource[indexPath.row].likeBy = updatedLikeBy
                            cell.likesLabel.text = "\(self.datasource[indexPath.row].likeBy.count) likes"
                            sender.setImage(UIImage(systemName: "heart"), for: .normal)
                            
                        }
                    }
                } else {
                    // Post was not already liked by user, time to like it
                    let updatedLikeBy = post.likeBy + [currentUserID]
                    docRef.updateData(["likeBy": updatedLikeBy]) { error in
                        if let error = error {
                            print("Error updating document: \(error)")
                            
                        } else {
                            self.datasource[indexPath.row].likeBy = updatedLikeBy
                            cell.likesLabel.text = "\(self.datasource[indexPath.row].likeBy.count) likes"
                            sender.setImage(UIImage(systemName: "heart.fill"), for: .normal)
                        }
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    // Ask user if he want to save the photo. If yes, save it to the local device.
    @objc func savePhotoButtonTapped(_ sender: UIButton) {
        guard let cell = sender.superview?.superview?.superview as? PostCell, let indexPath = tableview.indexPath(for: cell) else { return }
        let post = datasource[indexPath.row]
        let alertController = UIAlertController(title: "Save Photo", message: "Do you want to save this photo to your device?", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
                // Code to save photo goes here
                UIImageWriteToSavedPhotosAlbum(post.image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Ask user if he want to save the photo. If yes, save it to the local device.
    @objc func commentButtonTapped(_ sender: UIButton) {
        guard let cell = sender.superview?.superview?.superview as? PostCell, let indexPath = tableview.indexPath(for: cell) else { return }
        let post = datasource[indexPath.row]
        postID = post.documentID
        performSegue(withIdentifier: commentSegue, sender: nil)
    }
    // To confirm that photo is saved
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            if let error = error {
                // Handle error
                let errorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
            } else {
                // Photo saved successfully
                let alertControlller = UIAlertController(title: "Photo Saved", message: "Photo is sucessfully saved to photo library", preferredStyle: .alert)
                alertControlller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertControlller, animated: true, completion: nil)
            }
    }
    
    func dateString(date: Date) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 1
        formatter.allowedUnits = [.day, .hour, .minute]
        return (formatter.string(from: date, to: Date.now) ?? "unknown") + " ago"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == commentSegue,
           let nextVC = segue.destination as? CommentViewController{
            nextVC.postID = postID
            print(postID)
        }
    }
    
}
