#
#  Be sure to run `pod spec lint XPNetworking.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

 

  s.name         = "XPNetworking"
  s.version      = "0.0.3"
  s.summary      = "面向对象的网络编程框架"
  s.homepage     = "https://github.com/HolyLe/XPNetworking.git"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

   s.author       = { "麻小亮" => "zshnr1993@qq.com" }
   s.platform     = :ios, "8.0"
   s.ios.deployment_target = '8.0'
   s.source       = { :git => "https://github.com/HolyLe/XPNetworking.git", :tag =>          s.version.to_s } 

  s.public_header_files = 'XPNetworking/Network/XPNetworking.h'
  s.source_files  = "XPNetworking/Network/XPNetworking.h"
  s.requires_arc = true
  s.subspec 'XPRequest' do |ss|
     ss.source_files = 'XPNetworking/Network/XPRequest/**/*.{h,m}'
     ss.dependency "AFNetworking"
     ss.dependency "XPNetworking/XPCache"
  end
  s.subspec 'XPCache' do |ss|
     ss.public_header_files = 'XPNetworking/Network/XPCache/XPCache.h'
     ss.source_files = 'XPNetworking/Network/XPCache/*.{h,m}'
     ss.dependency "YYCache"
  end

  

  

end
