# CameraPreviewController

[![CI Status](http://img.shields.io/travis/DragonCherry/CameraPreviewController.svg?style=flat)](https://travis-ci.org/DragonCherry/CameraPreviewController)
[![Version](https://img.shields.io/cocoapods/v/CameraPreviewController.svg?style=flat)](http://cocoapods.org/pods/CameraPreviewController)
[![License](https://img.shields.io/cocoapods/l/CameraPreviewController.svg?style=flat)](http://cocoapods.org/pods/CameraPreviewController)
[![Platform](https://img.shields.io/cocoapods/p/CameraPreviewController.svg?style=flat)](http://cocoapods.org/pods/CameraPreviewController)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

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
extension ViewController: CameraPreviewControllerFaceDetectionDelegate {
    public func cameraPreviewDetectedFaces(preview: GPUImageView, features: [CIFeature]?, aperture: CGRect, orientation: UIDeviceOrientation) {
        guard let faces = features as? [CIFaceFeature], faces.count > 0 else {
            return
        }
        // do something
    }
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
