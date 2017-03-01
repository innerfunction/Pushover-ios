Pod::Spec.new do |s|

  s.name            = "Smokestack"
  s.version         = "0.8.4"
  s.summary         = "Smokestack CMS - SDK for iOS"
  s.description     = <<-DESC
    An iOS client SDK for the Smokestack mobile CMS.
    DESC
  s.homepage        = "https://github.com/innerfunction/smokestack-ios"

  s.license         = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author          = { "Julian Goacher" => "julian.goacher@innerfunction.com" }

  s.platform        = :ios
  s.ios.deployment_target = '8.0'

  s.source          = { :git => "https://github.com/innerfunction/Smokestack-ios.git", :tag => "0.8.4" }
  s.source_files    = "Smokestack/Classes/Smokestack.h", "Smokestack/Classes/{cms,commands,content,db,forms,ui,utils}/*.{h,m}", "Smokestack/Classes/SSKeychain/*.{h,m}"
  s.requires_arc    = true

  s.frameworks      = "UIKit", "Foundation"

  s.libraries       = 'sqlite3'

  s.xcconfig        = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }

  s.dependency 'Q'
  s.dependency 'SCFFLD'
  s.dependency 'GRMustache'
  s.dependency 'MPMessagePack'

end
