environment_file = File.join(ENV["SRCROOT"], "Scripts", "environment.rb")
if File.exist?(environment_file)
  require "#{environment_file}"
end

require "erb"

if ENV["OPENVPN_USERNAME"].nil? || ENV["OPENVPN_PASSWORD"].nil? || ENV["OPENVPN_CONFIGURATION"].nil?
  puts "warning: VPN profile data is missing, you need to fill VPNProfile.swift manually."
  exit(true)
end

template_file = File.join(ENV["SRCROOT"], "Scripts", "vpn_profile_template.erb")
unless File.exist?(template_file)
  puts "error: Template file does not exist."
  exit(false)
end

output_file = File.join(ENV["SRCROOT"], "Tests", "VPNProfile.swift")
unless File.exist?(output_file)
  puts "error: Output file does not exist."
  exit(false)
end

OPENVPN_USERNAME = ENV["OPENVPN_USERNAME"]
OPENVPN_PASSWORD = ENV["OPENVPN_PASSWORD"]
OPENVPN_CONFIGURATION = ENV["OPENVPN_CONFIGURATION"]
OPENVPN_REMOTE_HOST = ENV["OPENVPN_REMOTE_HOST"]
OPENVPN_REMOTE_PORT = ENV["OPENVPN_REMOTE_PORT"]

template_content = File.read(template_file)
erb_template = ERB.new(template_content, nil, ">")

result = erb_template.result
File.write(output_file, result)
