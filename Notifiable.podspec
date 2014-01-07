
Pod::Spec.new do |s|


  s.name         = "Notifiable"
  s.version      = "0.0.1"
  s.platform     = :ios, '6.0'
  s.summary      = "Utility classes to integrate with Notifiable-Rails gem"

  s.dependency 'AFNetworking', '~> 1.3'
  s.frameworks   = ['MobileCoreServices.framework', 'SystemConfiguration']

  s.description  = <<-DESC
                   Utility classes to integrate with Notifiable-Rails gem
                   DESC

  s.homepage     = "https://github.com/FutureWorkshops/Notifiable-iOS"
  s.license      = { :type => 'Apache License Version 2.0', :file => 'LICENSE' }
  s.author       = { "Daniel Phillips" => "daniel@futureworkshops.com" }

  s.source       = { :git => "https://github.com/FutureWorkshops/Notifiable-iOS.git", :tag => "0.0.1" }

  s.source_files  = 'Notifiable-iOS'
  s.public_header_files = 'Notifiable-iOS/**/*.h'
  s.requires_arc = true 

end
