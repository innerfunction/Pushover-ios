Pod::Spec.new do |s|

  s.name            = "Pushover"
  s.version         = "0.0.1"
  s.summary         = "Pushover CMS mobile SDK for iOS"
  s.description     = <<-DESC
    An iOS client SDK for the Pushover content and document management system.
    DESC
  s.homepage        = "https://github.com/innerfunction/Pushover-ios"

  s.license         = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author          = { "Julian Goacher" => "julian.goacher@innerfunction.com" }

  s.platform        = :ios

  s.source          = { :git => "git@github.com:innerfunction/Pushover-ios.git" } #, :tag => "0.0.1" }
  s.source_files    = "Pushover/Classes/**/*.{h,m}"
  s.exclude_files   = "Pushover/Classes/wp/*.{h,m}", "Pushover/Classes/PlausibleDatabase/*.{h,m}"
  s.requires_arc    = true

  s.subspec 'plausedb' do |sp|
    sp.source_files     = "Pushover/Classes/PlausibleDatabase/*.{h,m}"
    sp.compiler_flags   = '-DPL_DB_PRIVATE=1 -DPL_MODULAR_SQLITE_IMPORT=1'
    sp.requires_arc     = false
  end

  # s.public_header_files = "Classes/**/*.h"

  s.frameworks      = "UIKit", "Foundation"

  s.libraries       = 'sqlite3'

  s.xcconfig        = { "HEADER_SEARCH_PATHS" => "$(SRCROOT)/**" }

  s.dependency 'Q'
  s.dependency 'SCFFLD'
  s.dependency 'GRMustache'

end
