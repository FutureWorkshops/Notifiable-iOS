
Pod::Spec.new do |s|


  s.name         = "FWTPushNotifications"
  s.version      = "0.0.2"
  s.summary      = "Utility classes to integrate with FWTPushNotificationServer gem"

  s.description  = <<-DESC
                   Utility classes to integrate with FWTPushNotificationServer gem
                   DESC

  s.homepage     = "https://github.com/FutureWorkshops/FWTPushNotifications"
  s.license      = { :type => 'Apache License Version 2.0', :file => 'LICENSE' }
  s.author       = { "Daniel Phillips" => "daniel@futureworkshops.com" }

  s.source       = { :git => "git@github.com:FutureWorkshops/FWTPushNotifications.git", :tag => "0.0.2" }

  s.source_files  = 'FWTPushNotifications'
  s.public_header_files = 'FWTPushNotifications/**/*.h'
  s.requires_arc = true 

  s.dependency 'AFNetworking'

end
