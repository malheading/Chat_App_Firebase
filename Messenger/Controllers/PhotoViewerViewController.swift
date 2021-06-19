//
//  PhotoViewerViewController.swift
//  Messenger
//
//  Created by 김정원 on 2021/02/10.
//

import UIKit

class PhotoViewerViewController: UIViewController {
    private var imageUrl:URL
    private let imageView:UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(with url:URL) {
        self.imageUrl = url
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Photo"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .black
        imageView.sd_setImage(with: imageUrl, completed: nil)
        view.addSubview(imageView)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
    }
    
    
    

}
