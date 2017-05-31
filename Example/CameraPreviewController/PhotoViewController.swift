//
//  PhotoViewController.swift
//  CameraPreviewController
//
//  Created by DragonCherry on 1/11/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import TinyLog
import PureLayout

class PhotoViewController: UIViewController {
    
    public var image: UIImage?
    
    private var didSetupConstraints: Bool = false
    private var imageView: UIImageView = {
        let view = UIImageView.newAutoLayout()
        view.contentMode = .scaleAspectFill
        return view
    }()
    private lazy var closeButton: UIButton = {
        let button = UIButton.newAutoLayout()
        button.setTitle("Close", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(pressedClose(sender:)), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        view.addSubview(closeButton)
        imageView.image = self.image
    }
    
    override func updateViewConstraints() {
        if !didSetupConstraints {
            imageView.autoPinEdgesToSuperviewEdges()
            closeButton.autoSetDimensions(to: CGSize(width: 50, height: 40))
            closeButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
            closeButton.autoPinEdge(toSuperviewEdge: .top, withInset: 40)
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        closeButton.showBorder()
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
