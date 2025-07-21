#!/usr/bin/env ruby

# Skaletek KYC iOS Setup for Podfile integration
# Add this to your Podfile's post_install hook:
#
# post_install do |installer|
#   installer.pods_project.targets.each do |target|
#     flutter_additional_ios_build_settings(target)
#   end
#   
#   # Skaletek KYC Auto Setup
#   load File.join(File.dirname(__FILE__), 'Pods', 'skaletek_kyc', 'skaletek_kyc_setup.rb')
#   SkaletekKYC.setup_ios_project
# end

require 'fileutils'

module SkaletekKYC
  def self.setup_ios_project
    puts "\n🔧 Skaletek KYC: Configuring iOS project..."
    
    project_root = find_flutter_project_root
    unless project_root
      puts "⚠️ Skaletek KYC: Unable to locate project directory"
      return
    end
    
    puts "📱 Skaletek KYC: Initializing for #{File.basename(project_root)}"
    
    # Setup paths
    ios_runner_path = File.join(project_root, 'ios', 'Runner')
    app_delegate_path = File.join(ios_runner_path, 'AppDelegate.swift')
    
    # Perform setup
    setup_aws_integration(project_root, ios_runner_path)
    configure_app_delegate(app_delegate_path)
    
    puts "✅ Skaletek KYC: iOS integration completed successfully!"
    puts "ℹ️ Next: Add Swift Package dependencies in Xcode (see README for details)"
  end
  
  private
  
  def self.find_flutter_project_root
    current_path = Dir.pwd
    
    # Walk up from current directory to find pubspec.yaml
    while current_path != '/'
      if File.exist?(File.join(current_path, 'pubspec.yaml'))
        return current_path
      end
      current_path = File.dirname(current_path)
    end
    
    nil
  end
  
  def self.setup_aws_integration(project_root, target_path)
    # Try to find AWS config files in various locations
    source_paths = [
      # From the bundled resources
      File.join(project_root, 'ios', 'Pods', 'skaletek_kyc', 'SkaletekKYC.bundle'),
      # From plugin assets (local development)
      File.join(project_root, 'assets'),
      # From plugin directory structure
      File.join(File.dirname(__FILE__), '..', 'assets'),
      # From pub cache
      Dir.glob(File.expand_path('~/.pub-cache/hosted/pub.dev/skaletek_kyc-*/assets')).first
    ].compact
    
    source_path = source_paths.find { |path| Dir.exist?(path) }
    
    unless source_path
      puts "⚠️ Skaletek KYC: Unable to configure AWS integration"
      return false
    end
    
    # Setup configuration files
    copied_files = []
    config_count = 0
    ['amplifyconfiguration.json', 'awsconfiguration.json'].each do |config_file|
      source_file = File.join(source_path, config_file)
      target_file = File.join(target_path, config_file)
      
      next unless File.exist?(source_file)
      
      FileUtils.cp(source_file, target_file)
      copied_files << config_file
      config_count += 1
    end
    
    # Add files to Xcode project to ensure they're included in the build
    add_files_to_xcode_project(project_root, copied_files) if copied_files.any?
    
    puts "ℹ️ Skaletek KYC: AWS services configured (#{config_count} files)" if config_count > 0
    true
  end
  
  def self.add_files_to_xcode_project(project_root, files_to_add)
    begin
      require 'xcodeproj'
    rescue LoadError
      puts "⚠️ Skaletek KYC: xcodeproj gem not available, files may need manual Xcode configuration"
      puts "ℹ️ Install with: gem install xcodeproj"
      return false
    end
    
    project_path = File.join(project_root, 'ios', 'Runner.xcodeproj')
    return false unless File.exist?(project_path)
    
    begin
      project = Xcodeproj::Project.open(project_path)
      runner_target = project.targets.find { |target| target.name == 'Runner' }
      
      unless runner_target
        puts "⚠️ Skaletek KYC: Could not find Runner target in Xcode project"
        return false
      end
      
      runner_group = project.main_group['Runner']
      unless runner_group
        puts "⚠️ Skaletek KYC: Could not find Runner group in Xcode project"
        return false
      end
      
      files_added = 0
      files_to_add.each do |file_name|
        # Check if file reference already exists
        existing_file = runner_group.children.find { |child| child.display_name == file_name }
        
        if existing_file
          puts "ℹ️ Skaletek KYC: #{file_name} already exists in Xcode project"
          next
        end
        
        # Create file reference
        file_ref = runner_group.new_reference(file_name)
        
        # Add to Copy Bundle Resources build phase
        resources_phase = runner_target.resources_build_phase
        build_file = resources_phase.add_file_reference(file_ref)
        
        if build_file
          files_added += 1
          puts "ℹ️ Skaletek KYC: Added #{file_name} to Xcode project"
        end
      end
      
      if files_added > 0
        project.save
        puts "✅ Skaletek KYC: Successfully updated Xcode project (#{files_added} files)"
      end
      
      true
    rescue => e
      puts "⚠️ Skaletek KYC: Could not modify Xcode project: #{e.message}"
      puts "ℹ️ Files copied but may need manual addition to Xcode project"
      puts "ℹ️ Manually add the JSON files to your Runner target in Xcode"
      false
    end
  end
  
  def self.configure_app_delegate(app_delegate_path)
    return unless File.exist?(app_delegate_path)
    
    content = File.read(app_delegate_path)
    
    # Check if already configured
    if content.include?("import Amplify") && content.include?("AWSCognitoAuthPlugin")
      puts "ℹ️ Skaletek KYC: App delegate already configured"
      return
    end
    
    puts "ℹ️ Skaletek KYC: Configuring app initialization..."
    
    # Add imports after UIKit
    unless content.include?("import Amplify")
      content.gsub!(/import UIKit/, "import UIKit\nimport Amplify\nimport AWSCognitoAuthPlugin")
    end
    
    # Add Amplify configuration before GeneratedPluginRegistrant
    amplify_config = <<~SWIFT
      
      // Configure Amplify for Face Liveness Detection
      do {
        try Amplify.add(plugin: AWSCognitoAuthPlugin())
        try Amplify.configure()
        print("✅ Amplify configured with Auth plugin for Skaletek KYC")
      } catch {
        print("⚠️ Could not initialize Amplify for Skaletek KYC: \\(error)")
      }
    SWIFT
    
    unless content.include?("try Amplify.add(plugin: AWSCognitoAuthPlugin())")
      content.gsub!(
        /(\s+)GeneratedPluginRegistrant\.register\(with: self\)/,
        "#{amplify_config.chomp}\n\\1GeneratedPluginRegistrant.register(with: self)"
      )
    end
    
    File.write(app_delegate_path, content)
    puts "✅ Skaletek KYC: App initialization configured"
  end
  
  # Utility method to validate setup
  def self.validate_setup(project_root)
    ios_runner_path = File.join(project_root, 'ios', 'Runner')
    required_files = ['amplifyconfiguration.json', 'awsconfiguration.json']
    
    missing_files = required_files.reject do |file|
      File.exist?(File.join(ios_runner_path, file))
    end
    
    if missing_files.empty?
      puts "✅ Skaletek KYC: All configuration files present"
      true
    else
      puts "⚠️ Skaletek KYC: Missing configuration files: #{missing_files.join(', ')}"
      false
    end
  end
  
end

# Auto-run if called directly (for testing)
if __FILE__ == $0
  SkaletekKYC.setup_ios_project
end