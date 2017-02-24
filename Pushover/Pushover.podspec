Pod::Spec.new do |s|

  s.name            = "Pushover"
  s.version         = "0.0.33"
  s.summary         = "Pushover CMS mobile SDK for iOS"
  s.description     = <<-DESC
    An iOS client SDK for the Pushover content and document management system.
    DESC
  s.homepage        = "https://github.com/innerfunction/Pushover-ios"

  s.license         = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author          = { "Julian Goacher" => "julian.goacher@innerfunction.com" }

  s.platform        = :ios
  s.ios.deployment_target = '8.0'

  s.source          = { :git => "git@github.com:innerfunction/Pushover-ios.git", :tag => "0.0.33" }
  s.source_files    = "Pushover/Classes/Pushover.h", "Pushover/Classes/{cms,commands,content,db,forms,ui,utils}/*.{h,m}", "Pushover/Classes/SSKeychain/*.{h,m}"
  s.requires_arc    = true

  s.frameworks      = "UIKit", "Foundation"

  s.libraries       = 'sqlite3'

  s.xcconfig        = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }

  s.dependency 'Q'
  s.dependency 'SCFFLD'
  s.dependency 'GRMustache'
  s.dependency 'MPMessagePack'

end
