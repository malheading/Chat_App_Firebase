//
//  ViewController.swift
//  Messenger
//
//  Created by 김정원 on 2021/02/10.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class ConversationsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let tableView:UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self,
                       forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let noConversationLabel:UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        view.addSubview(tableView)
        view.addSubview(noConversationLabel)
        setupTableView()
        fetchConversations()
    }
    
    @objc private func didTapComposeButton(){
        //New Conversation Create Controller
        let vc = NewConversationViewController()
        vc.completion = {[weak self]result in
            /*
             print("\(result)")
             result의 형태는 다음과 같다.
             ["name" : "Joe Smith", "email":"joe-gmail-com"]
             */
            
            self?.createNewConversation(result: result)
        }
        
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    private func createNewConversation(result:[String:String]){
        // ChatViewController 클래스의 object vc를 불러온다.
        ///name: 대화 상대 이름, email: 대화 상대의 email이다. 헷갈리지 말 것
        guard let name = result["name"], let email = result["email"]else{
            print("(ConversationsViewController)Error!: Failed to get name and email.")
            return
        }
        
        let vc = ChatViewController(with: email)
        vc.title = name    //대화 상대
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()
    }
    override func viewDidLayoutSubviews() { //subview가 나타나도록 오버라이드
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func validateAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil{ //현재 로그인이 되어있지 않다면...
            let vc = LoginViewController()  //view controller class
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
//            present(nav, animated: true)
            present(nav, animated: false)
        }
    }
    
    private func setupTableView(){  // 대화 테이블뷰를 셋업한다.
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func fetchConversations(){
        tableView.isHidden = false
    }
    
}

extension ConversationsViewController:UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Hello World!"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = ChatViewController()
        vc.title = "Jenny Smith"    //대화 상대
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}

