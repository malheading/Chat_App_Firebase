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
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender:SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}

class ChatViewController: MessagesViewController {//Dependencies중에 하나인 MessageKit의 MessagesViewController를 사용한다.

    public var otherUserEmail:String
    public var isNewConversation = false
    
    init(with email:String) {
        otherUserEmail = email
        super.init(nibName: nil, bundle: nil)   // MessagesViewController를 return하는 init
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var messages = [Message]()
    
    private let selfSender = Sender(photoURL: UserDefaults.standard.value(forKey: "profile_picture_url") as? String ?? "",
                                    senderId: "1",
                                    displayName: UserDefaults.standard.value(forKey: "name") as? String ?? "Me")    //추후에 Firebase에서 가져올 예정
    
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
}

extension ChatViewController:InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // 채팅방에서 Send Button을 눌렀을 때
        // 비어있는 채팅은 보내지지 않도록
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else{ // 비어있는 채팅이다.
            return
        }
        
        print("\(text)")
        
        if isNewConversation{   // 만약 대화가 처음이라면?
            // Database에 새로운 대화를 생성
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: <#T##Message#>, completion: <#T##(Bool) -> Void#>)
            
        }else{  // 만약 대화가 처음이 아니라면?
            // 기존 Database에 추가(append)
            
        }
        
    }
    
}

extension ChatViewController:MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]  //MessageKit에서는 section을 단위로 사용하기 때문에
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
