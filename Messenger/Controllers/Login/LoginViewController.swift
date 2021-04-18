//
//  LoginViewController.swift
//  Messenger
//
//  Created by 김정원 on 2021/02/10.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        //add subview for logo
        //앞에서 만든 Subview들을 등록해야한다.
        view.addSubview(scrollView) //VStack 대신에 UIScrollView로 만들었고
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        
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
        passwordField.frame = CGRect(x: 30,
                                    y: emailField.bottom+10,   //imageView
                                    width: scrollView.width - 60,
                                   height: 52)    //일반적으로 text edit의 height?
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: passwordField.width, height: 52)

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
        //여기에 Firebase Log in을 적용할 예정//
        //Firebase Log in을 시도 했을 때
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {[weak self]authResult, error in
            guard let strongSelf = self else{
                return
            }
            guard let result=authResult, error==nil else{
                print("Failed to log in user with email:\(email)")
                return
            }
            let user=result.user
            print("Logged in with user: \(email)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            
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
