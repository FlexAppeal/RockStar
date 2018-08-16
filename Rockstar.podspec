#
# Be sure to run `pod lib lint Rockstar.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Rockstar'
  s.version          = '0.1.0'
  s.summary          = 'Swifty APIs for creating clean apps'

  s.description      = <<-DESC
APIs designed to leverage the existing ecosystems, providing swifty APIs to create faster and more robust apps.
                       DESC

  s.swift_version = '4.1'
  s.homepage         = 'https://github.com/RockStarSwift/RockStar'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'joannis' => 'joannis@orlandos.nl' }
  s.source           = { :git => 'https://github.com/RockStarSwift/RockStar.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/joannisorlandos'

  s.swift_version           = '4.0'

  s.ios.deployment_target   = '10.0'
  s.ios.source_files = 'Sources/RockstarUIKit/**/*'
  s.osx.source_files = 'Sources/RockstarAppKit/**/*'

  s.source_files     = 'Sources/Rockstar/**/*'

  s.subspec 'RockstarTexture' do |sp|
    sp.dependency 'RockstarUIKit'
  end

  s.subspec 'RockstarNIO' do |sp|
    sp.dependency 'SwiftNIO'
    sp.dependency 'SwiftNIOTransportServices'
    sp.dependency 'SwiftNIOWebSocket'
end

  #s.dependency 'SwiftNIOTransportServices', '~> 0.2.0'
end
