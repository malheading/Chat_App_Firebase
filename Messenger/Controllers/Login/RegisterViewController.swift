//
//  RegisterViewController.swift
//  Messenger
//
//  Created by 김정원 on 2021/02/10.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {
    
    private let scrollView:UIScrollView = {
        //이것도 클로져(closure)??
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        //        scrollView.
        return scrollView
    }()
    
    private let imageView:UIImageView = {
        let imageView = UIImageView()
        //        imageView.image = UIImage(named:"logo")
        imageView.image = UIImage(systemName: "person")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
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
    
    private let firstNameField:UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue //return (엔터)를 눌렀을 때, 다음 UI로 이동하는 버튼?
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First Name..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let lastNameField:UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue //return (엔터)를 눌렀을 때, 다음 UI로 이동하는 버튼?
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Last Name..."
        
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
    
    
    private let registerButton:UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Register"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        
        //UI와 Action을 Connect하는 것
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self  //extension으로 LoginViewController type을 UITextFieldDelegate로 assign
        passwordField.delegate = self
        
        //add subview for logo
        //앞에서 만든 Subview들을 등록해야한다.
        view.addSubview(scrollView) //VStack 대신에 UIScrollView로 만들었고
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        gesture.numberOfTouchesRequired = 1
        gesture.numberOfTapsRequired = 1
        
        
        imageView.addGestureRecognizer(gesture)
    }
    
    //오버라이드 함수 : Subview를 불러오는 함수
    //여기서 Subview의 프레임을 지정해줘야한다.
    @objc private func didTapChangeProfilePic(){
        print("Change pic called")
        presentPhotoActionSheet()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds  //view에 scrollView를 central로 정하는 것과 동일?
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (view.width - size)/2,
                                 y: 100,
                                 width: size,
                                 height: size)
        imageView.layer.cornerRadius = imageView.width/2.0
        
        firstNameField.frame = CGRect(x: 30,
                                      y: imageView.bottom+10,   //imageView
                                      width: scrollView.width - 60,
                                      height: 52)    //일반적으로 text edit의 height?
        firstNameField.textColor = .black
        lastNameField.frame = CGRect(x: 30,
                                     y: firstNameField.bottom+10,   //imageView
                                     width: scrollView.width - 60,
                                     height: 52)    //일반적으로 text edit의 height?
        lastNameField.textColor = .black
        emailField.frame = CGRect(x: 30,
                                  y: lastNameField.bottom+10,   //imageView
                                  width: scrollView.width - 60,
                                  height: 52)    //일반적으로 text edit의 height?
        emailField.textColor = .black
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+10,   //imageView
                                     width: scrollView.width - 60,
                                     height: 52)    //일반적으로 text edit의 height?
        passwordField.textColor = .black
        registerButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: passwordField.width, height: 52)
        
    }
    
    //버튼 눌렀을 때 수행하는 함수
    @objc private func registerButtonTapped(){
        emailField.resignFirstResponder()   //이메일에 있던 커서 제거
        passwordField.resignFirstResponder()    //패스워드에 있던 커서? 제거
        guard let lastName = lastNameField.text,
              let firstName = firstNameField.text,
              let email = emailField.text,
              let password = passwordField.text,
              !lastName.isEmpty, !firstName.isEmpty ,!email.isEmpty, !password.isEmpty, password.count>=6 else {
            //email 또는 password가 비었을 때
            alertUserLoginError()
            return
        }
        //여기에 Firebase Log in을 적용할 예정//
        
        DatabaseManager.shared.userExists(with: email, completion: {[weak self]exists in
            guard let strongSelf = self else{
                return
            }
            guard !exists else{
                //user alread exists
                strongSelf.alertUserLoginError(message: "Email already exists.")
                return
            }
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: {authResult, error in
                
                guard authResult != nil , error == nil else{
                    print("Error creating user")
                    return
                }
                
                DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firstName,
                                                                    lastName: lastName,
                                                                    emailAddress: email))   //database에 정보를 입력
                
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)   //이 클래스의 정보를 공유하기 위해서 dismiss
            })
        })
    }
    
    func alertUserLoginError(message:String="Please enter all information to register."){
        let alert = UIAlertController(title: "woops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
        
    }
    
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}


extension RegisterViewController : UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //textField에서 return을 눌렀을 때
        if textField == emailField{
            passwordField.becomeFirstResponder()    //textField가 emailField일 때는 passwordField가 FirstResponder()
        }
        else if textField == passwordField{ //textField == passwordField이면은?
            registerButtonTapped() //함수 호출
        }
        return true
    }
    
}


extension RegisterViewController:UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func presentPhotoActionSheet(){
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take photo", style: .default, handler: {[weak self]_ in //[weak self]는 왜 해야하나??
            self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose photo", style: .default, handler: {[weak self]_ in
            self?.presentPhotoPicker()
        }))
        present(actionSheet, animated: true)
    }
    
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera //camera를 사용하는 PickerController
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true) //present 해야지 뜬다?
    }
    
    func presentPhotoPicker(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary   //photoLibrary 사용하는 PickerController
        vc.delegate = self
        vc.allowsEditing = true
        present(vc,animated: true)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //info를 통해서 데이터가 들어온다?
        picker.dismiss(animated: true, completion: nil)
        print(info)
        
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {   //InfoKey에서 Jump Definition으로 들어간다.
            return
        }
        self.imageView.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //cancel이 눌렸을 때?
        picker.dismiss(animated: true, completion: nil)
    }
}
