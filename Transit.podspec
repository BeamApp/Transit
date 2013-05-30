#
# Be sure to run `pod spec lint Transit.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about the attributes see http://docs.cocoapods.org/specification.html
#
Pod::Spec.new do |s|
  s.name         = "Transit"
  s.version      = "0.0.1"
  s.summary      = "Library to Bridge between JavaScript and iOS, OSX."
  s.homepage     = "http://github.com/BeamApp/Transit"
  s.license      = 'new BSD'
  s.authors      = { "Heiko Behrens" => "HeikoBehrens@gmx.de", "Marcel Jackwerth" => "marceljackwerth@gmail.com"}
  s.source       = { :git => "https://github.com/BeamApp/Transit.git", :commit => "b225cca637243b3a76d60a6a647f8d27ad206cb3" }
  s.platform     = :ios, '5.0'
  s.source_files = 'source/objc/*.{h,m}'
  s.public_header_files = 'source/objc/Transit.h'
  s.requires_arc = true
  s.dependency 'SBJson', '~> 3.2'
end
