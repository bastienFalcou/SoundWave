#
# Be sure to run `pod lib lint SoundWave.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SoundWave'
  s.version          = '0.1.2'
  s.summary          = 'Illustrate your SoundWave on the fly 🚀'
  s.homepage         = 'https://github.com/bastienFalcou/SoundWave'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Bastien Falcou' => 'bastien.falcou@hotmail.com' }
  s.source           = { :git => 'https://github.com/bastienFalcou/SoundWave.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/BastienFalcou'

  s.description      = <<-DESC
    SoundWave is a customizable view representing sounds over time:
    - Add and display audio metering level values on the fly
    - Set array of pre-existing audio metering level and play / pause / resume
    - Customize background, gradient start and end colors, metering level bar properties, etc.
                       DESC

  s.ios.deployment_target = '9.0'
  s.source_files = 'SoundWave/Classes/**/*'
  
  # s.resource_bundles = {
  #   'SoundWave' => ['SoundWave/Assets/*.png']
  # }

  # s.screenshots = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
