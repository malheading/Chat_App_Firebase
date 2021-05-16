//
//  LoginViewController.swift
//  Messenger
//
//  Created by 김정원 on 2021/02/10.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView:UIScrollView = {
        //이것도 클로져(closure)??
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        //        scrollView.
        return scrollView
    }()
    
    private let imageView:UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named:"logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField:UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue //return (엔터)를 눌렀을 때, 다음 UI로 이동하는 버튼?
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email address..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField:UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        //        field.returnKeyType = .continue //return (엔터)를 눌렀을 때, 다음 UI로 이동하는 버튼?
        field.returnKeyType = .done //return (엔터)를 눌렀을 때, 완료로 설정
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .lightGray
        field.isSecureTextEntry = true
        
        return field
    }()
    
    private let loginButton:UIButton = {
        let button = UIButton()
        button.setTitle("Log in", for: .normal)
        button.backgroundColor = .link  //하이퍼 링크를 걸었을 때의 파란색
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        
        return button
    }()
    
    //private let facebookLoginButton = FBLoginButton()
    private let facebookLoginButton:FBLoginButton = {
        let facebookLoginButton = FBLoginButton()
        facebookLoginButton.permissions = ["email","public_profile"]
        return facebookLoginButton
    }()
    
    private let googleLoginButton = GIDSignInButton()   //구글 로그인 버튼 인스턴스 생성
    
    private var loginObserver:NSObjectProtocol? //옵저버 추가
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification,
                                                               object: nil,
                                                               queue: .main,
                                                               using: {[weak self] _ in
                                                                guard let strongSelf = self else{
                                                                    return
                                                                }
                                                                
                                                                strongSelf.dismiss(animated: true, completion: nil)
                                                               })
        
        // 구글아이디가 이미 있는 경우에는 자동으로 로그인 됩니다.
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().signIn()
        
        title = "Log in"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        
        //UI와 Action을 Connect하는 것
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self  //extension으로 LoginViewController type을 UITextFieldDelegate로 assign
        passwordField.delegate = self
        
        facebookLoginButton.delegate = self
        
        //add subview for logo
        //앞에서 만든 Subview들을 등록해야한다.
        view.addSubview(scrollView) //VStack 대신에 UIScrollView로 만들었고
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLoginButton)    //구글 로그인 버튼 추가
    }//end of viewDidLoad()
    
    deinit {//메모리 아끼기 위해서 loginObserver가 dismiss될 때 제거
        if let observer = loginObserver{
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    //오버라이드 함수 : Subview를 불러오는 함수
    //여기서 Subview의 프레임을 지정해줘야한다.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds  //view에 scrollView를 central로 정하는 것과 동일?
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (view.width - size)/2,
                                 y: 100,
                                 width: size,
                                 height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom+10,   //imageView
                                  width: scrollView.width - 60,
                                  height: 52)    //일반적으로 text edit의 height?
        emailField.textColor = .black   //이메일 텍스트 색상은 검정입니다.
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+10,   //imageView
                                     width: scrollView.width - 60,
                                     height: 52)    //일반적으로 text edit의 height?
        passwordField.textColor = .black    //패스워드 텍스트 글씨도 검정
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: passwordField.width, height: 52)
        
        facebookLoginButton.frame = CGRect(x: 30, y: loginButton.bottom + 10, width: loginButton.width, height: 52)
        
        googleLoginButton.frame = CGRect(x: 30, y: facebookLoginButton.bottom + 10, width: facebookLoginButton.width, height: 52)
    }
    
    //버튼 눌렀을 때 수행하는 함수
    @objc private func loginButtonTapped(){
        emailField.resignFirstResponder()   //이메일에 있던 커서 제거
        passwordField.resignFirstResponder()    //패스워드에 있던 커서? 제거
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count>=6 else {
            //email 또는 password가 비었을 때
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)  //스피너 보여주기
        
        //Firebase Log in을 시도 했을 때
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {[weak self]authResult, error in
            guard let strongSelf = self else{
                return
            }
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()    // 스피너 없애기?
            }
            
            guard let result=authResult, error==nil else{
                print("Failed to log in user with email:\(email)")
                return
            }
            let user=result.user
            
            UserDefaults.standard.set(email, forKey: "email")   // 현재 로그인한 사람의 이메일을 캐쉬에 저장?
            
            print("Logged in with user: \(email)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)   // 현재 컨트롤러(로그인 컨트롤러)를 제거한다?
            
        })
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "woops!", message: "Please enter all information of your ID or password", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
        
    }
    
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}


extension LoginViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //textField에서 return을 눌렀을 때
        if textField == emailField{
            passwordField.becomeFirstResponder()    //textField가 emailField일 때는 passwordField가 FirstResponder()
        }
        else if textField == passwordField{ //textField == passwordField이면은?
            loginButtonTapped() //함수 호출
        }
        return true
    }
}

extension LoginViewController:LoginButtonDelegate{
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //no operation now
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        //페이스북 로그인 버튼 클릭 했을 때
        guard let token = result?.token?.tokenString else {//로그인 실패 했을 때는?
            print("페이스북 이용한 유저 로그인 실패 - 토큰을 가져오지 못했습니다.")
            return
        }
        //페이스북에서 받아온 정보(이름, 이메일) -> Database에 넣어야 한다.
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields":"email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        facebookRequest.start { (_, result, error) in
            guard let result = result as? [String:Any], //result << ["name": 김정원, "id": 3800614720006917, "email": jsi00046@nate.com]
                  error==nil else{//error가 nil이 아니면 에러 발생
                print("Failed to make facebook graph request.")
                return
            }
            
//            print("\(result)")  //debug...
//            return  //end function here for debuging...
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String:Any],
                  let data = picture["data"] as? [String:Any],
                  let pictureUrl = data["url"] as? String else{// String object이기 때문에 []를 사용??
                print("Failed to get email and name from facebook results.")
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")   // 현재 로그인한 사람의 이메일을 캐쉬에 저장?
            
            //Firebase의 DatabaseManager(내가 만든 클래스의 객체)에 보내준다.
            DatabaseManager.shared.userExists(with: email, completion: {exists in
                if !exists{//만약 계정이 존재하지 않으면 -> 데이터베이스에 넣어줘야한다.
                    let chatUser = ChatAppUser(firstName: firstName as String,
                                               lastName: lastName as String,
                                               emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: {success in
                        if success{//데이터베이스에 유저 입력을 성공하면
                            guard let url = URL(string: pictureUrl) else{//이미지의 URL을 url변수에 저장한다.
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
                                guard let data = data else{//url에서 데이터를 얻어온다.
                                    //data 받아오는 것을 실패 하면?
                                    print("failed to get data from facebook")
                                    return
                                }
                                //upload image here
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: {result in
                                    switch result {
                                    case .success(let downloadURL):
                                        UserDefaults.standard.setValue(downloadURL, forKey: "profile_picture_url")  //database에 업로드된 이미지의 저장 장소를 저장한다?
                                        print(downloadURL)
                                    case .failure(let error):
                                        print("storage manager error: \(error)")
                                    }
                                })
                            }).resume()
                        }
                    })
                }
            })
            
            //페이스북으로 로그인 성공을 파이어베이스로 보낸다.(credential은 firebase에서 사용)
            let credential = FacebookAuthProvider.credential(withAccessToken: token)//credential 생성
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: {[weak self]authResult, error in
                guard let strongSelf = self else{
                    return
                }
                guard authResult != nil, error == nil else{
                    print("Facebook credential log in failed, MFA may be needed - \(String(describing: error))")
                    return
                }
                print("로그인 성공")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        }
        
        
    }
    
    
}
