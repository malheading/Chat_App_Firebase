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
        
        tableView.tableHeaderView = createTableHeader()
        // Do any additional setup after loading the view.
    }
    
    func createTableHeader()->UIView?{
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{ // 로그인때 캐시에 저장한 이메일 정보를 불러온다.
            print("Error!:Failed to load user email from UserDefaults.standard")
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)  // DatabaseManager 클래스에 직접 만든 함수
        let filename = safeEmail + "_profile_picture.png"
        
        let path = "images/"+filename   //데이터베이스에 있는 프로파일 이미지의 경로
        
        let headerView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: self.view.width,
                                              height: 300)) // UIView의 위치 및 사이즈(height는 고정)
        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (headerView.width-150)/2,
                                                  y: 150/2,
                                                  width: 150,
                                                  height: 150)) // 실제 헤더뷰에 들어갈 이미지 컨테이너?
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.cornerRadius = imageView.width/2
        imageView.layer.masksToBounds = true   // subView를 headerView에 맞추서 자를것인지?
        
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(for: path, completion: {[weak self] result in
            // result는 Result 클래스로, .success()의 반환값 또는 .failure()의 반환값으로 이루어져있다??
            switch result{
            case .success(let url):
                self?.downloadImage(imageView: imageView, url:url)
            case .failure(let error):
                print("ProfileViewController.swift : Failed to get download url: \(error)")
            }
        })
        
        return headerView
    }
    func downloadImage(imageView:UIImageView, url:URL){
        URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
            guard let data=data, error==nil else{
                return
            }
            DispatchQueue.main.async {  //이거 왜쓰는거임?
                let image = UIImage(data: data)
                imageView.image = image
            }
        }).resume() //URLSession의 dataTask에서 return하는 request는 'resume()'으로 활성화해야한다??
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
