source "https://rubygems.org"

# Fastlane for iOS/Android automation
gem "fastlane", "~> 2.222"

# Plugins can be added here
# Example:
# gem "fastlane-plugin-firebase_app_distribution"

# Additional gems for better performance and compatibility
gem "cocoapods", "~> 1.15"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
