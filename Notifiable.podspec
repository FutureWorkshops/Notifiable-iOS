
Pod::Spec.new do |s|


  s.name         = "Notifiable"
  s.version      = "0.0.11"
  s.platform     = :ios, '6.0'
  s.summary      = "Utility classes to integrate with notifiable-rails gem"

  s.dependency 'AFNetworking', '~> 1.3'
  s.frameworks   = ['MobileCoreServices', 'SystemConfiguration']

  s.description  = <<-DESC
                   Utility classes to integrate with Notifiable-Rails gem. See more at http://github.com/FutureWorkshops/Notifiable-Rails.
                   DESC

  s.homepage     = "https://github.com/FutureWorkshops/Notifiable-iOS"
  s.license      = { :type => 'Apache License Version 2.0', :file => 'LICENSE' }
  s.authors       = { "Daniel Phillips" => "daniel@futureworkshops.com", "Kamil Kocemba" => "kamil@futureworkshops.com" }

  s.source       = { :git => "https://github.com/FutureWorkshops/Notifiable-iOS.git", :tag => "0.0.11" }

  s.source_files  = 'Notifiable-iOS'
  s.public_header_files = 'Notifiable-iOS/**/*.h'
  s.requires_arc = true 

end
