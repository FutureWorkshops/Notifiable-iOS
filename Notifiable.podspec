Pod::Spec.new do |s|


  s.name         = "Notifiable"
  s.version      = "1.2.3"
  s.platform     = :ios, '8.0'
  s.summary      = "Utility classes to integrate with Notifiable-Rails gem"

  s.ios.frameworks  = 'CoreServices'
  s.frameworks   = 'SystemConfiguration'

  s.description  = <<-DESC
                   Utility classes to integrate with Notifiable-Rails gem (https://github.com/FutureWorkshops/notifiable-rails).
                   You can see a sample of how to use the FWTNotifiable SDK on github: (https://github.com/FutureWorkshops/Notifiable-iOS/tree/master/Sample)
                   DESC

  s.homepage     = "https://github.com/FutureWorkshops/Notifiable-iOS"
  s.license      = { :type => 'Apache License Version 2.0', :file => 'LICENSE' }
  s.author       = { "Future Workshops" => "info@futureworkshops.com" }

  s.source       = { :git => "https://github.com/FutureWorkshops/Notifiable-iOS.git", :tag => s.version }

  s.source_files  = 'Notifiable-iOS/**/*.{h,m}'
  s.public_header_files = 'Notifiable-iOS/FWTNotifiableManager.h', 'Notifiable-iOS/Logger/FWTNotifiableLogger.h', 'Notifiable-iOS/Model/FWTNotifiableDevice.h', 'Notifiable-iOS/Category/*.h'
  s.module_name = 'FWTNotifiable'
  s.requires_arc = true 

end
