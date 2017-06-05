//
//  ViewController.swift
//  CameraPreviewController
//
//  Created by DragonCherry on 01/10/2017.
//  Copyright (c) 2017 DragonCherry. All rights reserved.
//

import UIKit
import GPUImage
import SwiftARGB
import CameraPreviewController
import TinyLog

extension UIView {
    func showBorder() {
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
    }
}

class ViewController: CameraPreviewController {
    
    let buttonHeight: CGFloat = 40
    let textSize: CGFloat = 10
    let bgColor: UIColor = UIColor(rgbHex: 0xEEEEFF)
    let recognitionColor: UIColor = UIColor(rgbHex: 0xEEFFEE)
    let effectColor: UIColor = UIColor(rgbHex: 0xFFEEEE)
    let textColor: UIColor = .black
    
    var didSetupConstraints = false
    
    // Buttons for basic functionalities
    lazy var btnToggleCamera: UIButton = {
        let button = UIButton.newAutoLayout()
        button.setTitle("Toggle Camera", for: .normal)
        button.backgroundColor = self.bgColor
        button.setTitleColor(self.textColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: self.textSize)
        button.addTarget(self, action: #selector(self.pressedToggleCamera), for: .touchUpInside)
        return button
    }()
    lazy var btnToggleFlash: UIButton = {
        let button = UIButton.newAutoLayout()
        button.setTitle("Toggle Flash", for: .normal)
        button.backgroundColor = self.bgColor
        button.setTitleColor(self.textColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: self.textSize)
        button.addTarget(self, action: #selector(self.pressedToggleFlash), for: .touchUpInside)
        return button
    }()
    lazy var btnTakePhoto: UIButton = {
        let button = UIButton.newAutoLayout()
        button.setTitle("Take Photo", for: .normal)
        button.backgroundColor = self.bgColor
        button.setTitleColor(self.textColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: self.textSize)
        button.addTarget(self, action: #selector(self.pressedTakePhoto), for: .touchUpInside)
        return button
    }()
    lazy var btnTakeVideo: UIButton = {
        let button = UIButton.newAutoLayout()
        button.setTitle("Take Video", for: .normal)
        button.backgroundColor = self.bgColor
        button.setTitleColor(self.textColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: self.textSize)
        button.addTarget(self, action: #selector(self.pressedTakeVideo), for: .touchUpInside)
        return button
    }()
    
    // Buttons for recognization functionalities
    lazy var btnToggleDetectFace: UIButton = {
        let button = UIButton.newAutoLayout()
        button.setTitle("Enable Face Detection", for: .normal)
        button.backgroundColor = self.recognitionColor
        button.setTitleColor(self.textColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: self.textSize)
        button.addTarget(self, action: #selector(self.pressedToggleDetectFace), for: .touchUpInside)
        return button
    }()
    
    // Buttons for effect functionalities
    lazy var btnAddFilter: UIButton = {
        let button = UIButton.newAutoLayout()
        button.setTitle("Add Filter", for: .normal)
        button.backgroundColor = self.effectColor
        button.setTitleColor(self.textColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: self.textSize)
        button.addTarget(self, action: #selector(self.pressedAddFilter), for: .touchUpInside)
        return button
    }()
    lazy var btnClearFilters: UIButton = {
        let button = UIButton.newAutoLayout()
        button.setTitle("Clear Filters", for: .normal)
        button.backgroundColor = self.effectColor
        button.setTitleColor(self.textColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: self.textSize)
        button.addTarget(self, action: #selector(self.pressedClearFilters), for: .touchUpInside)
        return button
    }()
    
    override func loadView() {
        super.loadView()
        cameraPosition = .back          // initial camera position
        
        // set delegates
        delegate = self
        layoutSource = self
        faceDetectionDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add your views
        view.addSubview(btnAddFilter)
        view.addSubview(btnClearFilters)
        view.addSubview(btnToggleDetectFace)
        view.addSubview(btnToggleCamera)
        view.addSubview(btnToggleFlash)
        view.addSubview(btnTakePhoto)
        view.addSubview(btnTakeVideo)
    }
    
    override func updateViewConstraints() {
        
        if !didSetupConstraints {
            
            /* Filter */
            btnAddFilter.autoSetDimension(.height, toSize: buttonHeight)
            btnAddFilter.autoMatch(.width, to: .width, of: view, withMultiplier: 1/2)
            btnAddFilter.autoPinEdge(toSuperviewEdge: .leading)
            btnAddFilter.autoPinEdge(toSuperviewEdge: .bottom)
            
            btnClearFilters.autoSetDimension(.height, toSize: buttonHeight)
            btnClearFilters.autoMatch(.width, to: .width, of: view, withMultiplier: 1/2)
            btnClearFilters.autoPinEdge(toSuperviewEdge: .trailing)
            btnClearFilters.autoPinEdge(toSuperviewEdge: .bottom)
            
            /* Face Detection */
            btnToggleDetectFace.autoSetDimension(.height, toSize: buttonHeight)
            btnToggleDetectFace.autoPinEdge(toSuperviewEdge: .leading)
            btnToggleDetectFace.autoPinEdge(toSuperviewEdge: .trailing)
            btnToggleDetectFace.autoPinEdge(.bottom, to: .top, of: btnAddFilter)
            
            /* Basic */
            let btnBasicCount: CGFloat = 4
            btnToggleCamera.autoSetDimension(.height, toSize: buttonHeight)
            btnToggleCamera.autoMatch(.width, to: .width, of: view, withMultiplier: 1/btnBasicCount)
            btnToggleCamera.autoPinEdge(toSuperviewEdge: .leading)
            btnToggleCamera.autoPinEdge(.bottom, to: .top, of: btnToggleDetectFace)

            btnToggleFlash.autoSetDimension(.height, toSize: buttonHeight)
            btnToggleFlash.autoMatch(.width, to: .width, of: view, withMultiplier: 1/btnBasicCount)
            btnToggleFlash.autoPinEdge(.leading, to: .trailing, of: btnToggleCamera)
            btnToggleFlash.autoPinEdge(.bottom, to: .top, of: btnToggleDetectFace)
            
            btnTakePhoto.autoSetDimension(.height, toSize: buttonHeight)
            btnTakePhoto.autoMatch(.width, to: .width, of: view, withMultiplier: 1/btnBasicCount)
            btnTakePhoto.autoPinEdge(.bottom, to: .top, of: btnToggleDetectFace)
            btnTakePhoto.autoPinEdge(.leading, to: .trailing, of: btnToggleFlash)
            
            btnTakeVideo.autoSetDimension(.height, toSize: buttonHeight)
            btnTakeVideo.autoMatch(.width, to: .width, of: view, withMultiplier: 1/btnBasicCount)
            btnTakeVideo.autoPinEdge(.bottom, to: .top, of: btnToggleDetectFace)
            btnTakeVideo.autoPinEdge(.leading, to: .trailing, of: btnTakePhoto)
            
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        btnToggleCamera.showBorder()
        btnToggleFlash.showBorder()
        btnTakePhoto.showBorder()
        btnTakeVideo.showBorder()
        btnToggleDetectFace.showBorder()
        btnAddFilter.showBorder()
        btnClearFilters.showBorder()
    }
}

extension ViewController {
    
    public func pressedTakeVideo(sender: UIButton) {
        if isRecordingVideo {
            finishRecording()
            sender.setTitle("Take Video", for: .normal)
        } else {
            startRecording()
            sender.setTitle("Finish Recording", for: .normal)
        }
    }
    
    public func pressedTakePhoto(sender: UIButton) {
        takePhoto({ image in
            let photoVC = PhotoViewController()
            photoVC.image = image
            self.present(photoVC, animated: true, completion: nil)
        })
    }
    
    public func pressedToggleCamera(sender: UIButton) {
        flipCamera()
        switch cameraPosition {
        case .back:
            sender.setTitle("Front Camera", for: .normal)
        default:
            sender.setTitle("Back Camera", for: .normal)
        }
    }
    
    public func pressedToggleFlash(sender: UIButton) {
        switch torchMode {
        case .auto:
            torchMode = .on
            sender.setTitle("Torch: Turn on", for: .normal)
        case .on:
            torchMode = .off
            sender.setTitle("Torch: Turn off", for: .normal)
        case .off:
            torchMode = .auto
            sender.setTitle("Torch: Set auto", for: .normal)
        }
    }
    
    public func pressedToggleDetectFace(sender: UIButton) {
        isFaceDetectorEnabled = !isFaceDetectorEnabled
        if isFaceDetectorEnabled {
            faceDetectFrequency = 10
            sender.setTitle("Disable Face Detection", for: .normal)
        } else {
            sender.setTitle("Enable Face Detection", for: .normal)
        }
    }
    
    public func pressedAddFilter(sender: UIButton) {
        let sepiaFilter = GPUImageSepiaFilter()
        sepiaFilter.intensity = 1
        add(filter: sepiaFilter)
    }
    public func pressedClearFilters(sender: UIButton) {
        removeFilters()
    }
}

// MARK: - Implementation for CameraPreviewControllerDelegate
extension ViewController: CameraPreviewControllerDelegate {
    
    func cameraPreview(_ controller: CameraPreviewController, didSaveVideoAt url: URL) {
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path) {
            UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(finishedWriteVideoToSavedPhotosAlbum), nil)
        } else {
            logw("Given path: \(url.absoluteString) is not compatible with \"Saved Photos Album\"")
        }
    }
    
    func cameraPreview(_ controller: CameraPreviewController, willOutput sampleBuffer: CMSampleBuffer, with sequence: UInt64) {
        
    }
    func cameraPreview(_ controller: CameraPreviewController, willFocusInto locationInView: CGPoint, tappedLocationInImage locationInImage: CGPoint) {
        logi("Focusing location in view: \(locationInView)")
        logi("Focusing location(ratio) in image: \(locationInImage)")
    }
}

// MARK: Handles Video Capture
extension ViewController {
    func finishedWriteVideoToSavedPhotosAlbum(_ videoPath: String, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            logc("Error: \(error.localizedDescription)")
        } else {
            logi("Successfully saved a video file in Photo Library: \(videoPath)")
        }
    }
}

// MARK: - Implementation for CameraPreviewControllerLayoutSource
extension ViewController: CameraPreviewControllerLayoutSource {
    func cameraPreviewNeedsLayout(_ controller: CameraPreviewController, preview: GPUImageView) {
        view.addSubview(preview)
        preview.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        preview.autoPinEdge(toSuperviewEdge: .bottom, withInset: buttonHeight * 3)
    }
}

// MARK: - Implementation for CameraPreviewControllerFaceDetectionDelegate
extension ViewController: CameraPreviewControllerFaceDetectionDelegate {
    func cameraPreview(_ controller: CameraPreviewController, detected faceFeatures: [CIFaceFeature]?, aperture: CGRect, orientation: UIDeviceOrientation) {
        
        showFaceRects(faceFeatures, aperture: aperture, orientation: orientation)
        
        if let faces = faceFeatures {
            logd("detected face count: \(faces.count)")
            for (i, face) in faces.enumerated() {
                log("### FACE NO.\(i + 1)")
                log("hasFaceAngle: \(face.hasFaceAngle) -> \(face.faceAngle)")
                log("leftEyeClosed: \(face.leftEyeClosed)")
                log("hasLeftEyePosition: \(face.hasLeftEyePosition) -> \(face.leftEyePosition)")
                log("rightEyeClosed: \(face.rightEyeClosed)")
                log("hasRightEyePosition: \(face.hasRightEyePosition) -> \(face.rightEyePosition)")
                log("hasMouthPosition: \(face.hasMouthPosition) -> \(face.mouthPosition)")
                log("hasSmile: \(face.hasSmile)")
            }
        }
    }
}


