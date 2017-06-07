#
# Be sure to run `pod lib lint CameraPreviewController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CameraPreviewController'
  s.version          = '1.4.0'
  s.summary          = 'Basic camera preview controller based on GPUImage library inside.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Full-customizable camera preview controller. Supports picture, video, filter, auto & manual touch focusing, face detection, and etc.'

  s.homepage         = 'https://github.com/DragonCherry/CameraPreviewController'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DragonCherry' => 'dragoncherry@naver.com' }
  s.source           = { :git => 'https://github.com/DragonCherry/CameraPreviewController.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'CameraPreviewController/Classes/**/*'
  
  # s.resource_bundles = {
  #   'CameraPreviewController' => ['CameraPreviewController/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'TinyLog'
  s.dependency 'GPUImage'
  s.dependency 'PureLayout'
end
