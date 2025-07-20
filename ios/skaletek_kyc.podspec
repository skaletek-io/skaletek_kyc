#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint skaletek_kyc.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'skaletek_kyc'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for Skaletek KYC verification services with AWS Amplify Face Liveness.'
  s.description      = <<-DESC
A Flutter plugin that provides comprehensive KYC verification services including document scanning and face liveness detection using AWS Amplify.
                       DESC
  s.homepage         = 'https://github.com/skaletek-io/skaletek_kyc'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Skaletek' => 'support@skaletek.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # AWS Amplify compatibility - dependencies added via Swift Package Manager in consumer app
  s.ios.deployment_target = '14.0'
  
  # Bundle AWS configuration files so they're available
  s.resource_bundles = {
    'SkaletekKYC' => ['../assets/*.json']
  }
  
  # Include the setup script for Podfile integration
  s.resources = ['skaletek_kyc_setup.rb']
end 