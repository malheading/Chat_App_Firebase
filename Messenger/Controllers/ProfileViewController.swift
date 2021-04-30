//
//  ProfileViewController.swift
//  Messenger
//
//  Created by 김정원 on 2021/02/10.
//

import UIKit
import FirebaseAuth //firebase auth 사용
import FBSDKLoginKit
import GoogleSignIn

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let data=["Log Out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
}

//extension을 추가함으로써 추가적인 상속을 더할 수 있다. (기존: UIViewController만 상속 -> 변경: UIViewController + UITableViewDataSource
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { //logout 클릭 했을 때
        tableView.deselectRow(at: indexPath, animated: true)    //unhighlight the cell
        
        let actionSheet = UIAlertController(title: "", //Alert 컨트롤러 생성
                                            message: "정말로 로그아웃 하시겠습니까?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "로그아웃", //Alert 액션 추가(버튼 추가라고 보면 된다.)
                                            style: .destructive,
                                            handler: {[weak self] _ in
                                                guard let strongSelf=self else{
                                                    return
                                                }
                                                do {
                                                    //  실제 로그아웃 수행하는 부분
                                                    try FirebaseAuth.Auth.auth().signOut()
                                                    try FBSDKLoginKit.LoginManager().logOut()
                                                    try GIDSignIn.sharedInstance()?.signOut()
                                                    
                                                    let vc = LoginViewController()
                                                    let nav = UINavigationController(rootViewController: vc)
                                                    nav.modalPresentationStyle = .fullScreen
                                                    strongSelf.present(nav, animated: true)
                                                } catch  {
                                                    print("Failed to log out")
                                                }
                                            }))
        actionSheet.addAction(UIAlertAction(title: "취소",
                                            style: .cancel,
                                            handler: nil    //아무 행동도 안하면 된다.
        ))
        present(actionSheet, animated: true)
        
        
    }
    
}
