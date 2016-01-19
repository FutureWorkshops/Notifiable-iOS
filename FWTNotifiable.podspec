Pod::Spec.new do |s|


  s.name         = "FWTNotifiable"
  s.version      = "0.0.13"
  s.platform     = :ios, '8.0'
  s.summary      = "Utility classes to integrate with Notifiable-Rails gem"

  s.dependency 'AFNetworking', '~> 3.0.4'
  s.ios.frameworks  = 'MobileCoreServices'
  s.frameworks   = 'SystemConfiguration'

  s.description  = <<-DESC
                   Utility classes to integrate with Notifiable-Rails gem (https://github.com/FutureWorkshops/notifiable-rails).
                   DESC

  s.homepage     = "https://github.com/FutureWorkshops/Notifiable-iOS"
  s.license      = { :type => 'Apache License Version 2.0', :file => 'LICENSE' }
  s.author       = { "Daniel Phillips" => "daniel@futureworkshops.com" }

  s.source       = { :git => "https://github.com/FutureWorkshops/Notifiable-iOS.git", :tag => s.version }

  s.source_files  = 'Notifiable-iOS/**/*.{h,m}'
  s.public_header_files = 'Notifiable-iOS/FWTNotifiableManager.h', 'Notifiable-iOS/Logger/FWTNotifiableLogger.h', 'Notifiable-iOS/Category/*.h'
  s.module_name = 'FWTNotifiable'
  s.requires_arc = true 

end
