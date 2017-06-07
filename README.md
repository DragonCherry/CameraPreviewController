# CameraPreviewController

[![CI Status](http://img.shields.io/travis/DragonCherry/CameraPreviewController.svg?style=flat)](https://travis-ci.org/DragonCherry/CameraPreviewController)
[![Version](https://img.shields.io/cocoapods/v/CameraPreviewController.svg?style=flat)](http://cocoapods.org/pods/CameraPreviewController)
[![License](https://img.shields.io/cocoapods/l/CameraPreviewController.svg?style=flat)](http://cocoapods.org/pods/CameraPreviewController)
[![Platform](https://img.shields.io/cocoapods/p/CameraPreviewController.svg?style=flat)](http://cocoapods.org/pods/CameraPreviewController)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

I'm writing this since I couldn't find a open source with complete basic source to start develop camera application from, and is based on GPUImage library inside.

This example contains the following features.

1) front camera preview / still capture / video capture

2) back camera preview / still capture / video capture

3) flipping camera

4) torch control

5) tap to focus

6) add/remove filter

7) face detection

8) pinch to zoom in/out

I'm going to add more features that every camera application must have.

Please don't hesitate to contribute on this project. Any advice and suggestions will be greatly appreciated.

### Functions

- To take photo,

```Swift
takePhoto({ image in
    let photoVC = PhotoViewController()
    photoVC.image = image
    self.present(photoVC, animated: true, completion: nil)
})
```

- To take video,

```Swift
// to start
startRecordingVideo()

// to finish
finishRecordingVideo()

// to handle success
extension ViewController: CameraPreviewControllerDelegate {
    func cameraPreview(_ controller: CameraPreviewController, didSaveVideoAt url: URL) {
        // which is file url in temporary directory
    }
    func cameraPreview(_ controller: CameraPreviewController, didFailSaveVideoWithError error: Error) {
    }
    ...
}
```

- To change camera,

```Swift
flipCamera()
switch cameraPosition {
    // do something
}
```

- To control torch,

```Swift
torchMode = .on
torchMode = .off
torchMode = .auto
```

- To add, remove filters

```Swift
add(filter: filter)
removeFilters()
```

- To detect face,

```Swift
// set true somewhere
isFaceDetectorEnabled = true

// handle result
func cameraPreview(_ controller: CameraPreviewController, detected faceFeatures: [CIFaceFeature]?, aperture: CGRect, orientation: UIDeviceOrientation) {
    guard let faces = faceFeatures, faces.count > 0 else {
        return
    }
    // do something
}
```

## Requirements

Xcode8, Swift 3

## Dependency

Sample: TinyLog, GPUImage, PureLayout, SwiftARGB, Dimmer

Pods: TinyLog, GPUImage, PureLayout

## Installation

CameraPreviewController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "CameraPreviewController"
```

## Author

DragonCherry, dragoncherry@naver.com

## License

CameraPreviewController is available under the MIT license. See the LICENSE file for more info.
