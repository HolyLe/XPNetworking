#
#  Be sure to run `pod spec lint XPNetworking.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

 

  s.name         = "XPNetworking"
  s.version      = "0.0.1"
  s.summary      = "面向对象的网络编程框架"




  s.homepage     = "https://github.com/HolyLe/XPNetworking.git"





  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

   s.author             = { "麻小亮" => "zshnr1993@qq.com" }
   s.platform     = :ios

   s.source       = { :git => "https://github.com/HolyLe/XPNetworking.git", :tag =>          s.version.to_s } 


  s.source_files  = "XPNetworking/Network/Tool/*.{h,m}"
 



 

  s.framework  = "UIKit"

  s.requires_arc = true
  s.dependency "AFNetworking", "~> 3.0"
  s.dependency "YYModel"

end
