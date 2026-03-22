Pod::Spec.new do |s|
  s.name             = 'smart_keyboard'
  s.version          = '0.1.0'
  s.summary          = 'Real-time keyboard height tracking for Flutter.'
  s.description      = <<-DESC
A Flutter plugin for real-time keyboard height tracking with configurable
throttling, and programmatic keyboard show/hide on iOS and Android.
                       DESC
  s.homepage         = 'https://github.com/smart-keyboard/smart_keyboard'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'smart_keyboard' => 'author@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version    = '5.0'
end
