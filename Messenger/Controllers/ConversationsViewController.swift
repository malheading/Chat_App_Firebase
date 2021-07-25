//
//  ViewController.swift
//  Messenger
//
//  Created by 김정원 on 2021/02/10.
//  채팅 테이블뷰의 Controller

import UIKit
import FirebaseAuth
import JGProgressHUD

struct Conversation {
    let id:String
    let name:String
    let otherUserEmail:String
    let latestMessage:LatestMessage
}

struct SearchResult {
    let name: String
    let email: String
}

struct LatestMessage {
    let date:String
    let text:String
    let isRead:Bool
}


class ConversationsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()    // User Defined Struct의 배열
    
    public var email:String?    // 대화 상대의 email
    public var name:String?     // 대화 상대의 이름 ( name )
    
    private var loginObserver:NSObjectProtocol?
    
    
    private let conversationsTableView:UITableView = {
        let table = UITableView()
        table.isHidden = true
//        table.register(UITableViewCell.self,  // Part12 에서 데이터베스의 내용을 테이블뷰로 가져오려면 바껴야 한다.
//                       forCellReuseIdentifier: "cell")
        table.register(ConversationTableViewCell.self,
                       forCellReuseIdentifier: "ConversationTableViewCell")
        
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
        view.addSubview(conversationsTableView)
        view.addSubview(noConversationLabel)
        setupTableView()
        fetchConversations()
        // database에서 기록되어 있는 대화들을 불러온다.
        startListeningForConversations()
        
        // notificationCenter의 obserber를 달아서 언제든 감지하도록 한다?
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification,
                                                               object: nil,
                                                               queue: .main,
                                                               using: {[weak self] _ in
            guard let strongSelf = self else{
                return
            }
            
            strongSelf.startListeningForConversations()
            // 목표가 완료되면(Conversations fetch) --> Obserber를 제거해야한다.
        })
    }
    
    private func startListeningForConversations(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            print("Error(ConversationsViewController.swift)!:Failed to get email from UserDefaults")
            return
        }
        
        print("###############################################################")
        print("##########  Start Listening For Conversations  ################")
        
        if let observer = loginObserver{
            NotificationCenter.default.removeObserver(observer)
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self]result in
            switch result{
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    print("************ Debug Area3 ************")
                    print(conversations)
                    
                    self?.conversations = conversations
                    return  // conversation is empty.
                }
                self?.conversations = conversations
                
                DispatchQueue.main.async { // main thread에게 일하라고 명령
                    self?.conversationsTableView.reloadData()    // tableView Update
                }
                
            case .failure(let error):
                print("ConversationsViewController.swift: Failed to get conversations from database - error:\(error)")
                return
            }
        }
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
            guard let strongSelf = self else{
                return
            }
            
            let currentConversations = strongSelf.conversations
            
            if let targetConversation = currentConversations.first(where: { // 나의 Conversations에서 상대방이 존재하는지 확인한다.
                // 상대방에게서 나와의 대화가 존재하는지 확인하는 것은 createNewConversation에서 확인한다 --> conversationId가 다르면 또 새로운 채팅방 만들어버리니까!!
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }){
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id:targetConversation.id)    // 이미 나에게 존재하는 채팅방이기 때문에
                vc.isNewConversation = false // 없던 채팅방에 새로 만들경우에는 필수
                vc.title = targetConversation.name    //대화 상대
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }else{
//                strongSelf.email = result.email
//                strongSelf.name = result.name
                strongSelf.createNewConversation(result: result)
            }
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    private func createNewConversation(result:SearchResult){
        // ChatViewController 클래스의 object vc를 불러온다.
        ///name: 대화 상대 이름, email: 대화 상대의 email이다. 헷갈리지 말 것
        let name = result.name
        let email = result.email
//        let currentUserSafeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        let otherUserSafeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        DatabaseManager.shared.OtherUserHasConversation(otherUserEmail:otherUserSafeEmail , completion: {[weak self]result in
            guard let strongSelf = self else{
                return
            }
            switch result {
            case .success(let existingConversationId):
                // TODO: append conversation to strongSelf.conversations
                let requestedConversation = DatabaseManager.shared.requestConversation(conversationId: existingConversationId, otherUserName: name, otherUserEmail: otherUserSafeEmail)
                guard let newConversation = requestedConversation else {
                    print("Error(ConversationsViewController-RequestedConversation Failed")
                    return
                }
                strongSelf.conversations.append(newConversation)    // ConversationsViewController.conversations에 추가한다
//                DatabaseManager.shared.appendConversation()
                
                let vc = ChatViewController(with: otherUserSafeEmail, id:existingConversationId)
                vc.isNewConversation = false
                vc.title = name    //대화 상대
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case.failure(_):
                //실패한거면 -> 상대방의 채팅에도 현재 대화가 없는거니까, 진짜 완선 새로 만들어야한다.
                let vc = ChatViewController(with: email, id:nil)    // 새로운 채팅방을 만들기 때문에 일단 id = nil
                vc.isNewConversation = true // 없던 채팅방에 새로 만들경우에는 필수
                vc.title = name    //대화 상대
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()
    }
    override func viewDidLayoutSubviews() { //subview가 나타나도록 오버라이드
        super.viewDidLayoutSubviews()
        conversationsTableView.frame = view.bounds
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
        conversationsTableView.delegate = self
        conversationsTableView.dataSource = self
    }

    private func fetchConversations(){
        conversationsTableView.isHidden = false
        
    }
    
}

extension ConversationsViewController:UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count  // fetch한 conversations의 개수를 return
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                                 for: indexPath) as! ConversationTableViewCell
        
        cell.configure(with: model) // cell configure??
        
//        cell.textLabel?.text = "Hello World!"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = conversations[indexPath.row]
        
        tableView.deselectRow(at: indexPath, animated: true)
        
//        let vc = ChatViewController(with: email ?? "Empty email")
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return tableView == self.conversationsTableView  // can Edit Row 모드를 실행시킬 TableView가 동일한지 확인
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // delete tableView row
            tableView.beginUpdates()
        
            // Database에서 현재 User의 Conversations에서도 지워줘야 한다.
            let selectedConversationId = conversations[indexPath.row].id
            DatabaseManager.shared.deleteConversation(conversationId: selectedConversationId, completion: {success in
                if success{
//                    self?.conversations.remove(at: indexPath.row) // data model에서 제거
                    
                    print("************ Debug Area2 ************\n")
                    print(self.conversations.count)
                    print("self.conversations value is : \n \(self.conversations)\n")
                    
                    // 남아있던 메시지가 1개였던 경우에는 databaseManager에서 return 되기 때문에, 강제로 tableView에서 제거
                    guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else{
                        print("Error(ConversationsViewController-editingStyle) : Failed to get current user email.")
                        return
                    }
                    // 데이터베이스에서 현재 계정의 대화들이 있는지 확인하는것
                    // --> 2021.07.11 : tableView(numberOfRowsInSection)의 개수와 일치하지 않으면 오류 발생한다
                    // --> 2021.07.12 : 만약에 데이터베이스에서 유저의 대화가 비어있으면 self.conversations:[Conversation] = [] 로 만들어버리게 변경
                    DatabaseManager.shared.isConversationEmpty(currentUserEmail: currentUserEmail, completion: {isEmpty in
                        if isEmpty{
                            // 만약 현재 유저의 데이터베이스에 conversations가 비어있으면,
                            tableView.deleteRows(at: [indexPath], with: .left)  // tableView에서 제거한다.
                        }
                    })
                    print("Succeeded to delete conversation! \n")
                } else{
                    print("Failed to delete conversation! T_T \n")
                }
            })
            
            tableView.endUpdates()
        }
    }
}

