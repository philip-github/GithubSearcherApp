//
//  DetailViewController.swift
//  GitHubSearcher
//
//  Created by Philip Twal on 4/20/20.
//  Copyright © 2020 Philip Altwal. All rights reserved.
//

import UIKit
import SafariServices

class DetailViewController: UIViewController {
    
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var mySearchBar: UISearchBar!
    @IBOutlet weak var myTableView: UITableView!
    
    
    var userDetail : UserDetail?
    var userRepos : [ReposModel]?
    var usersVM = UsersViewModel()
    var searchedRepos : [Items] = []
    var isSearching = false
    var userName : String?
    
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let formatedUrl = (ApiKeys.userReposUrl.rawValue + self.userName!).lowercased()
        
        // MARK: - fetching user detail data call
        self.usersVM.userDetailApiCall(url: formatedUrl) { (Detail, error) in
            self.userDetail = Detail
            
            DispatchQueue.main.async {
                if self.userDetail?.avatar != nil{
                  self.avatarImageView.getImage(url: (self.userDetail?.avatar)!)
                }
                
                self.userNameLabel.text = self.userDetail?.name ?? self.userName
                self.bioLabel.text = self.userDetail?.bio ?? "No biography on this user"
                self.emailLabel.text = self.userDetail?.email ?? "Nil Email"
                self.followersLabel.text = "Followers: \(String(describing: self.userDetail?.followers ?? 0))"
                self.followingLabel.text = "Following: \(String(describing: self.userDetail?.following ?? 0))"
                self.locationLabel.text = self.userDetail?.location ?? "Nil Location"
            }
        }
        
        let stringUrl = (ApiKeys.userReposUrl.rawValue + self.userName! + EndPionts.repos.rawValue).lowercased()
        
        // MARK: - fetching the user repos to be displayed in table view
        self.usersVM.userReposApiCall(url: stringUrl) { (reposModel, error) in
            self.userRepos = reposModel
            DispatchQueue.main.async {
                self.myTableView.reloadData()
            }
        }
    }
}



extension DetailViewController: UITableViewDelegate,UITableViewDataSource{
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isSearching{
            return self.searchedRepos.count
        }else{
            if self.userRepos != nil{
                return self.userRepos!.count
            }else{
                return 0
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath){
        if indexPath.row == usersVM.limit - 1{
            self.usersVM.limit += 30
            self.usersVM.currentPage += 1
            
            let stringUrl = (ApiKeys.userReposUrl.rawValue + self.userName! + EndPionts.repos.rawValue + Queries.repoPage.rawValue +  String(self.usersVM.currentPage)).lowercased()
            
            //MARK: - fetching the user repos to be paginated in the table view
            self.usersVM.userReposApiCall(url: stringUrl) { (reposModel, error) in
                if error == nil && reposModel != nil{
                    self.userRepos?.append(contentsOf: reposModel!)
                    DispatchQueue.main.async {
                        self.myTableView.reloadData()
                    }
                }
            }
        }
    }
    
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // check if the user has done some search to display the searched items in the tableView
        if isSearching{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? DetailCustomTableViewCell else {return UITableViewCell()}
            
            if self.searchedRepos.count > 0{
                let data = self.searchedRepos[indexPath.row]
                
                cell.reposNameLabel.text = data.name
                cell.forksLabel.text = "Forks :\(data.forks)"
                cell.starsLabel.text = "Stars :\(data.stars)"
                
                return cell
            }else{
                return cell
            }
        }else{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? DetailCustomTableViewCell else {return UITableViewCell()}
            
            if self.userRepos != nil{
                let data = self.userRepos![indexPath.row]
                
                cell.reposNameLabel.text = data.name
                cell.forksLabel.text = "Forks :\(data.forks)"
                cell.starsLabel.text = "Stars :\(data.stars)"
                
                return cell
            }else{
                return cell
            }
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        
        let data = self.userRepos![indexPath.row]
        let repoName = data.name
        let formatedUrl = (ApiKeys.safariUrl.rawValue + self.userName! + "/" + repoName).lowercased()
        showSafariVC(url: formatedUrl)
        
    }
    
    //MARK: - function for displaying user repo Web Page
    func showSafariVC(url : String){
        
        guard let url = URL(string: url) else {return}
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
}


extension DetailViewController : UISearchBarDelegate{
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        // cancel the previous api call to stop invoking the api while editing the search bar
        self.usersVM.fetchRepos?.cancel()
        timer.invalidate()
        self.searchedRepos = []
        self.usersVM.currentPage = 1
        self.usersVM.limit = 30
        
        if searchText == "" || searchText == " "{
            self.isSearching = false
            self.searchedRepos = []
            self.myTableView.reloadData()
            
        }else{
            isSearching = true
            // adding timer to prevent frequent reloading
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (_) in
                let trimmedUserName = self.userName?.replacingOccurrences(of: " ", with: "+")
                let trimmedRepo = searchText.replacingOccurrences(of: " ", with: "+")
                
                let urlString = "\(ApiKeys.userReposSearch.rawValue)\(trimmedRepo)+user:\(String(describing: trimmedUserName!))\(Queries.page.rawValue)\(self.usersVM.currentPage)"
                //MARK: - fetching the searched repos api call
                self.usersVM.userReposSearchApiCall(url: urlString) { (model, error) in
                    
                    if error == nil && model != nil{
                        self.searchedRepos = model!
                        DispatchQueue.main.async {
                            self.myTableView.reloadData()
                            
                        }
                    }
                }
            })
        }
    }
    
    //MARK: - resign the key board when search button pressed
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        searchBar.searchTextField.resignFirstResponder()
    }
}


extension DetailViewController {
    
    override func viewWillDisappear(_ animated: Bool) {
        self.usersVM.clear()
    }
}
