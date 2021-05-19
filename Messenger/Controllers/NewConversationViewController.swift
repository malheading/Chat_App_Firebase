//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by 김정원 on 2021/02/10.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {

    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String:String]]() //empty array create
    private var hasFetched = false  // default value of hasFetched is false
    
    private let searchBar:UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for Users..."
        return searchBar
    }()
    
    private let tableView:UITableView = {//사람의 검색 결과를 보여줄 테이블뷰
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self,
                       forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let noResultsLabel:UILabel = {// 사람 검색했는데 결과가 없을 때
        let label = UILabel()
        label.isHidden = true
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self   //사람 찾는 서치바의 delegate
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",    //검색을 취소하고 싶으면 우측위에 bar버튼
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()    //새로운 채팅방열기를 누르면은 서치바가 바로 나오도록
        
    }
    
    @objc func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }

}

extension NewConversationViewController:UISearchBarDelegate{
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else{
            print("Error003!: NewConversationController.swift -> searchBar is empty!")
            return
        }
        spinner.show(in: view)
        self.searchUser(query: text)
    }
    
    func searchUser(query: String){
        // Check the user id array is exist
        if hasFetched{
            // filter the users
        }else{
            // fetch from firebase and then filter users.
        }
        
    }
}
