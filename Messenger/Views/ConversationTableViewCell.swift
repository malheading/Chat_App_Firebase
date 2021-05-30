//
//  ConversationTableViewCell.swift
//  Messenger
//
//  Created by 김정원 on 2021/05/28.
//

import UIKit
import SDWebImage   // Image Download과 연관

class ConversationTableViewCell: UITableViewCell {
    
    static let identifier = "ConversationTableViewCell" // UITableViewCell의 identifier 참고
    
    private let userImageView:UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLabel:UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    private let userMessageLabel:UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // 처음 인스턴스가 만들어질 때
        // contentView 내용 참고할 것
        // contentView.addSubview 는 모델(Model) 영역 --> UI에 직접적으로 나타나는 부분이 아님
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 직접 만든 subview들의 View들을 추가한다 (UI적인 부분들)
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 100,
                                     height: 100)
        userNameLabel.frame = CGRect(x: userImageView.right + 10, // imageView의 우측 10
                                     y: 10,
                                     width: contentView.width - userImageView.width - 10 - 10,
                                     height: (contentView.height - 10 - 10)/2)
        userMessageLabel.frame = CGRect(x: userImageView.right + 10,
                                        y: userNameLabel.bottom + 10, // userNameLabel의 아래쪽 10
                                        width: contentView.width - userImageView.width - 10 - 10,
                                        height: (contentView.height - 10 - 10)/2)
        
    }
    
    public func configure(with model:Conversation){
        self.userNameLabel.text = model.name
        self.userMessageLabel.text = model.latestMessage.text
        
        let path = "images/\(model.otherUserEmail)_profile_picture.png"

        StorageManager.shared.downloadURL(for: path) { [weak self](result) in
            switch result{
            case .success(let url):
                DispatchQueue.main.async { // main thread에 가장 먼저 할당?
                    self?.userImageView.sd_setImage(with: url, completed: nil)  // url에서 이미지 다운받고 셋팅
                }
                
            case .failure(let error):
                print("Failed to get image url: \(error)")
            }
        }
        
    }
    
}
