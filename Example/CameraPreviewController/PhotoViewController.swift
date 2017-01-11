//
//  PhotoViewController.swift
//  CameraPreviewController
//
//  Created by DragonCherry on 1/11/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import TinyLog
import AttachLayout

class PhotoViewController: UIViewController {
    
    public var image: UIImage?
    
    private var imageView: UIImageView!
    private var btnClose: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        btnClose = UIButton(size: CGSize(width: 50, height: 40), title: "Close", textSize: 10, textColor: .black, backgroundColor: .white, target: self, selector: #selector(pressedClose))
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = self.image
        
        _ = view.attachFilling(imageView)
        _ = view.attach(btnClose, at: .topRight, insets: UIEdgeInsets(top: 40, left: 0, bottom: 0, right: 20))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        btnClose.showBorder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        logw("Not enough memory.")
    }
}

extension PhotoViewController {
    func pressedClose(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
