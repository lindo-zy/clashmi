#!/usr/bin/env ruby
# frozen_string_literal: true

# CI 用: 将 Xcode 工程的签名设置从上游写死的 Automatic/TNPM9PFX3W
# 改为使用 workflow 提供的团队/证书/描述文件 (Manual 签名)。
#
# 用法: ruby tools/ci/apply_signing.rb <project.pbxproj 所在目录> <TEAM_ID> <IDENTITY>
#          <主App Profile名> [<clashmiService Profile名>] [<clashmiWidget Profile名>]
#
# 依赖 xcodeproj gem (macOS runner 随 CocoaPods 预装)。

require 'xcodeproj'

project_path = ARGV[0] or abort 'usage: apply_signing.rb <project dir> <team> <identity> <main profile> [service profile] [widget profile]'
team         = ARGV[1] or abort 'missing team id'
identity     = ARGV[2] or abort 'missing signing identity'
main_profile = ARGV[3] or abort 'missing main provisioning profile name'
service_profile = ARGV[4].to_s.empty? ? main_profile : ARGV[4]
widget_profile  = ARGV[5].to_s.empty? ? main_profile : ARGV[5]

# 按 target 名称分配描述文件; 未列出的 target (如 LibVpnCore framework)
# 只设置团队与证书, 不设置描述文件。
profiles = {
  'Runner'                => main_profile,
  'clashmiService'        => service_profile,
  'clashmiWidgetExtension' => widget_profile,
}

project = Xcodeproj::Project.open(project_path)
project.targets.each do |target|
  next unless %w[Runner clashmiService clashmiWidgetExtension Library].include?(target.name)

  target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
    config.build_settings['DEVELOPMENT_TEAM'] = team
    config.build_settings['CODE_SIGN_IDENTITY'] = identity
    if profiles.key?(target.name)
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = profiles[target.name]
    else
      config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
    end
  end
  puts "signing applied: #{target.name} -> #{profiles[target.name] || '(no profile)'}"
end
project.save
puts 'Xcode signing settings updated.'
