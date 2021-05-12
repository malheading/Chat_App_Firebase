//
//  AppDelegate.swift
//  Messenger
//
//  Created by 김정원 on 2021/02/10.
//

//import UIKit
//import Firebase // Firebase import for use it.

//@main
//class AppDelegate: UIResponder, UIApplicationDelegate {
//
//
//
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        // Override point for customization after application launch.
//        FirebaseApp.configure() //Firebase configure firstr
//        return true
//    }
//
//    // MARK: UISceneSession Lifecycle
//
//    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
//        // Called when a new scene session is being created.
//        // Use this method to select a configuration to create the new scene with.
//        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//    }
//
//    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
//        // Called when the user discards a scene session.
//        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
//        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
//    }
//
//
//}



import UIKit
import Firebase     //import Firebase for use it
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool { //application이 launched 이후에
        
        FirebaseApp.configure() //Firebase configure firstr
        
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        return GIDSignIn.sharedInstance().handle(url)
        
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else{    // 구글 로그인 에러 체크
            if let error = error{
                print("Google Sign in Failed with error: \(error)")
            }
            return
        }
        print("Did signed in with google")
        
        let email = user.profile.email as String //  유저 이메일
        DatabaseManager.shared.userExists(with: email, completion: {exists in
            if !exists{ //Insert to Database
                let chatUser = ChatAppUser(firstName: user.profile.givenName,
                                           lastName: user.profile.familyName,
                                           emailAddress: email)
                
                DatabaseManager.shared.insertUser(with: chatUser, completion: {success in
                    if success{
                        //upload image here
                        if user.profile.hasImage{//구글은 이미지가 있는지 먼저 확인해준다.
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                print("Error! Failed to get image url from google")
                                return
                            }
                            URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
                                guard let data=data else{
                                    print("Error in google sign in! URL Session failed to get data from URL:\(String(describing: error))")
                                    return
                                }
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
                    }
                    return
                })
            }
        })
        
        guard let authentication = user.authentication else {
            print("Missing google Authentication")
            return
        }
        //구글로부터 로그인 Credential을 받아온다.
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        Firebase.Auth.auth().signIn(with: credential, completion: {authResult, error in
            guard error != nil else{
                print("Firebase auth with Google credential Failed:\(String(describing: error))")
                return
            }
            //  Google Login Succeeded
        })
        
        NotificationCenter.default.post(name: .didLogInNotification, object: nil)   //아직도 NotificationCenter가 뭔지 모르겠다
    }
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
        print("Google User was disconnected")
    }
    
}
