//
//  ViewController.swift
//  ios101-project5-tumbler
//

import UIKit
import Nuke

class ViewController: UIViewController, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        
        // Get the post-associated table view row
        let post = posts[indexPath.row]
        
        // Configure the cell (i.e. update UI elements like labels, image views, etc.)
        if let photo = post.photos.first {
            let photoURL = photo.originalSize.url
            
            Nuke.loadImage(with: photoURL, into: cell.postImageView)
        }
                    
        cell.postDescriptionLabel.text = post.caption.htmlDecoded
        
        return cell
    }
    

    @IBOutlet weak var tableView: UITableView!
    
    // A property to store the movies we fetch.
    private var posts: [Post] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        
        // For pull-to-refresh functionality
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        fetchPosts()
    }
    
    // MARK: Refresh Control Action
    @objc private func refreshData(_ sender: UIRefreshControl) {
        fetchPosts()
    }

    // MARK: Fetch Data Method
    func fetchPosts() {
        let url = URL(string: "https://api.tumblr.com/v2/blog/all-thats-interesting/posts/photo?api_key=1zT8CiXGXFcQDyMFG7RtcfGLwTdDjFUJnZzKJaWTmgyK4lKGYk")!
        let session = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                // End refreshing if there's an error
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                }
                return
            }

            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(statusCode) else {
                print("❌ Response error: \(String(describing: response))")
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                }
                return
            }

            guard let data = data else {
                print("❌ Data is NIL")
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                }
                return
            }

            do {
                let blog = try JSONDecoder().decode(Blog.self, from: data)

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.posts = blog.response.posts
                    self.tableView.reloadData()
                    //End the refresh control animation once the data is loaded
                    self.tableView.refreshControl?.endRefreshing()

                    print("✅ We got \(self.posts.count) posts!")
                    for post in self.posts {
                        print("🍏 Summary: \(post.summary)")
                    }
                }

            } catch {
                print("❌ Error decoding JSON: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
        }
        session.resume()
    }
}

extension String {
    var htmlDecoded: String {
        guard let data = data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
        }
        return self
    }
}
