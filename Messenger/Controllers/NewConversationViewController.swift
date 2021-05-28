//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by 김정원 on 2021/02/10.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {

    public var completion:(([String:String])->Void)?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String:String]]() //empty array create
    private var results = [[String:String]]() //empty result array
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
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self   //사람 찾는 서치바의 delegate
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",    //검색을 취소하고 싶으면 우측위에 bar버튼
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()    //새로운 채팅방열기를 누르면은 서치바가 바로 나오도록
    }
    
    override func viewDidLayoutSubviews() {/// ViewDidLoad에서 Subview에 추가하는 것 뿐만 아니라, Frame에 추가를해야한다??
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds   //tableView의 테두리크기는 view의 테두리 크기와 같다.
        noResultsLabel.frame = CGRect(x: view.width/4,
                                      y: view.height/2 - 100,
                                      width: view.width/2,
                                      height: 200)
        
    }
    
    @objc func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }

}

extension NewConversationViewController:UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //start conversation code here
        let targetUserData = results[indexPath.row]
        
        //dismissSelf()   // 직접 만든 함수 --> Defenition 참고
        dismiss(animated: true, completion: {[weak self] in
            self?.completion?(targetUserData)
        })
    }
    
}

extension NewConversationViewController:UISearchBarDelegate{
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {   //Search button클릭 되었을 때
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else{
            print("Error003!: NewConversationController.swift -> searchBar is empty!")
            return
        }
        
        searchBar.resignFirstResponder() // searchBar를 클릭하면 검색창에 바로 입력할 수 있도록 resign.
        
        results.removeAll() //results array를 초기화 <-- 이전 검색 기록이 남아있을 수 있으므로
        spinner.show(in: view)
        self.searchUser(query: text)
    }
    
    func searchUser(query: String){
        // Check the user id array is exist
        if hasFetched{
            // filter the users
            self.filterUsers(with: query)
        }else{
            // fetch from firebase and then filter users.
            DatabaseManager.shared.getAllUsers(completion: {[weak self] result in
                switch result{
                case.success(let userCollection):
                    self?.hasFetched = true
                    self?.users = userCollection
                    self?.filterUsers(with: query)
                case.failure(let error):
                    print("Error004!: Failed to completion of getAllUsers\(error)")
                }
            })
            
        }
        /* Update UI:
         filter users and either show result or show no result label*/
        
    }
    
    func filterUsers(with term:String){
        guard hasFetched else{
            return
        }
        self.spinner.dismiss(animated: true)
        
        var result:[[String:String]] = self.users.filter({
            guard let name = $0["name"]?.lowercased() else{
                return false
            }
            return name.hasPrefix(term.lowercased())
        })
        self.results = result
        
        updateUI()  // update UI replacing noResult label or result label
    }
    
    func updateUI(){
        if self.results.isEmpty{
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }else{
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
    
}
