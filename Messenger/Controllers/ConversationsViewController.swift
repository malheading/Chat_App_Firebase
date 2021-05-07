//
//  ViewController.swift
//  Messenger
//
//  Created by 김정원 on 2021/02/10.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {
    
//    private let tableView:UITableView = {
//        let table = UITableView()
//        table.register(<#T##nib: UINib?##UINib?#>, forCellReuseIdentifier: <#T##String#>)
//        return table
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
//    override func viewDidAppear(animated:bool){
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()
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

}

