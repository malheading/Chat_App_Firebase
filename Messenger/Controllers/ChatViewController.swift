//
//  ChatViewController.swift
//  Messenger
//
//  Created by 김정원 on 2021/05/07.
// 채팅방에 들어 갔을 때의 Controller

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message:MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

// MessageKind 아래에 String을 하나 만들어준다.
extension MessageKind {
    var messageKindString:String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}


struct Sender:SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

class ChatViewController: MessagesViewController {//Dependencies중에 하나인 MessageKit의 MessagesViewController를 사용한다.

    //DateFormatter : Expensive object이기 때문에 static으로 만들어서 계속 사용한다?? 아니면 클래스 내부에 public object로 만든다??
    public static var dateFormatter:DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }
    
    public var otherUserEmail:String
    public var isNewConversation = false
    
    init(with email:String) {
        otherUserEmail = email
        super.init(nibName: nil, bundle: nil)   // MessagesViewController를 return하는 init
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var messages = [Message]()  // 현재 채팅방 사람의 메시지 Array
    
    private var selfSender:Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String,
              let photoURL = UserDefaults.standard.value(forKey: "profile_picture_url") as? String,
              let name = UserDefaults.standard.value(forKey: "userFullName") as? String else{
            print("Error(ChatViewController.swift)!: email or photoURL or userFullName in UserDefaults is nil.")
//            print("\(UserDefaults.standard.value(forKey: "email"))")
//            print("\(UserDefaults.standard.value(forKey: "profile_picture_url"))")
//            print("\(UserDefaults.standard.value(forKey: "userFullName"))")
            return Sender(photoURL: "", senderId: "DUMMY_SENDER", displayName: "DUMMY_SENDER")
        }
        let selfSender = Sender(photoURL: photoURL,
                                senderId: email,
                                displayName: name)
        return selfSender
    }
    
// // 초창기에 사용하던 코드
//    private let selfSender = Sender(photoURL: UserDefaults.standard.value(forKey: "profile_picture_url") as? String ?? "",
//                                    senderId: "1",
//                                    displayName: UserDefaults.standard.value(forKey: "name") as? String ?? "Me")    //추후에 Firebase에서 가져올 예정
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        messages.append(Message(sender: selfSender,
//                                messageId: "1",
//                                sentDate: Date(),
//                                kind: .text("Hello World Message")))
//        messages.append(Message(sender: selfSender,
//                                messageId: "1",
//                                sentDate: Date(),
//                                kind: .text("Hello World Message.Hello World Message.Hello World Message.Hello World Message.")))
        
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

extension ChatViewController:InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // 채팅방에서 Send Button을 눌렀을 때
        // 비어있는 채팅은 보내지지 않도록
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageID = createMessageID() else{
            return // 비어있는 채팅이다.
        }
        
//        print("\(text)")
        
        if isNewConversation{   // 만약 대화가 처음이라면?
            // Database에 새로운 대화를 생성
            //20210523 : Message 만들어야 함.
            let mmesage:Message = Message(sender: selfSender,
                                          messageId: messageID,
                                          sentDate: Date(),
                                          kind: .text(text))
            
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,
                                                         name:self.title! /*현재 title이 대화 상대의 이름이다.*/ ,
                                                         firstMessage: mmesage,
                                                         completion: {success in
                // 내가 직접 만든 createNewConversation 에서 completion(true)를 하면 --> success = true
                if success{
                    print("message success")
                } else{
                    print("message failed")
                }
            })
            
        }else{  // 만약 대화가 처음이 아니라면?
            // 기존 Database에 추가(append)
        }
        
    }
    
    private func createMessageID() -> String? {
        /// Create messageID using senderEmail + datetime + otherEmail + randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            print("Error(ChatViewController.swift)!: Failed to get currentUserEmail from UserDefaults.")
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        print("newIdentifier is: \(newIdentifier)")
        return newIdentifier
    }
    
}

extension ChatViewController:MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        if let sender = selfSender{
            return sender
        }
        fatalError("FatalError(ChatViewController.wift):! selfSender is nil.")
        return Sender(photoURL: "", senderId: "DUMMY_SENDER_2", displayName: "DUMMY_SENDER_2")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]  //MessageKit에서는 section을 단위로 사용하기 때문에
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
