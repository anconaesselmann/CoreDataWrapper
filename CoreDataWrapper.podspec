Pod::Spec.new do |s|
  s.name             = 'CoreDataWrapper'
  s.version          = '0.1.4'
  s.summary          = 'A wrapper for core data'
  s.description      = <<-DESC
A wrapper for core data.
                       DESC
  s.homepage         = 'https://github.com/anconaesselmann/CoreDataWrapper'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'anconaesselmann' => 'axel@anconaesselmann.com' }
  s.source           = { :git => 'https://github.com/anconaesselmann/CoreDataWrapper.git', :tag => s.version.to_s }
  s.swift_version = '5.0'
  s.ios.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'
  s.source_files = 'CoreDataWrapper/Classes/**/*'
  s.frameworks = 'CoreData'
  s.dependency 'ValueTypeRepresentable'
  s.dependency 'URN'
end
