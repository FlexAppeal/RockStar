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
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'joannis' => 'joannis@orlandos.nl' }
  s.source           = { :git => 'https://github.com/RockStarSwift/RockStar.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/joannisorlandos'

  s.ios.deployment_target   = '10.0'
    s.source_files     = 'Sources/Rockstar/**/*'

  s.subspec 'RockstarCore' do |sp|
    sp.ios.source_files = 'Sources/RockstarUIKit/**/*'
    sp.osx.source_files = 'Sources/RockstarAppKit/**/*'
  end

  s.subspec 'RockstarTexture' do |sp|
    sp.source_files  = 'Sources/RockstarTexture/**/*'
  end

  s.subspec 'RockstarNIO' do |sp|
    sp.ios.deployment_target = '11.0'

    sp.dependency 'SwiftNIO'
    sp.dependency 'SwiftNIOTransportServices'
    sp.dependency 'SwiftNIOWebSocket'

    sp.source_files  = 'Sources/RockstarNIO/**/*'
  end
end
