# CameraPreviewController

[![CI Status](http://img.shields.io/travis/DragonCherry/CameraPreviewController.svg?style=flat)](https://travis-ci.org/DragonCherry/CameraPreviewController)
[![Version](https://img.shields.io/cocoapods/v/CameraPreviewController.svg?style=flat)](http://cocoapods.org/pods/CameraPreviewController)
[![License](https://img.shields.io/cocoapods/l/CameraPreviewController.svg?style=flat)](http://cocoapods.org/pods/CameraPreviewController)
[![Platform](https://img.shields.io/cocoapods/p/CameraPreviewController.svg?style=flat)](http://cocoapods.org/pods/CameraPreviewController)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

I'm writing this since I couldn't find a open source with complete basic source to start develop camera application from, and is based on GPUImage library inside.

This example contains the following features.

1) front camera preview / still capture

2) back camera preview / still capture

3) flipping camera

4) torch control

5) tap to focus

6) add/remove filter

7) face detection

I'm going to add more features that every camera application must have.

To-do

1) pinch to zoom

2) ?

Please don't hesitate contribute on this project. Any advice and suggestions will be greatly appreciated.

### Functions

- To take photo,

```
takePhoto({ image in
    let photoVC = PhotoViewController()
    photoVC.image = image
    self.present(photoVC, animated: true, completion: nil)
})
```

- To change camera,

```
flipCamera()
switch cameraPosition {
    // do something
}
```

- To control torch,

```
torchMode = .on
torchMode = .off
torchMode = .auto
```

- To add, remove filters

```
add(filter: filter)
removeFilters()
```

- To detect face,

```
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

Sample: TinyLog, GPUImage, AttachLayout, SwiftARGB

Pods: TinyLog, GPUImage, AttachLayout

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
