# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/util/execution'
require 'puppet/util/uuid_v5'
require 'puppet/util/plist'

# Implementation for the mac_profile type using the Resource API.
class Puppet::Provider::MacProfile::MacProfile < Puppet::ResourceApi::SimpleProvider
  def canonicalize(context, resources)
    resources.each do |resource|
      if resource.key?(:mobileconfig)
        mobileconfig = resource[:mobileconfig].is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive) ? resource[:mobileconfig].unwrap : resource[:mobileconfig]
        parsed_mobileconfig = Puppet::Util::Plist.parse_plist(mobileconfig) if mobileconfig.is_a?(String)
        mobileconfig = parsed_mobileconfig if !parsed_mobileconfig.nil? && parsed_mobileconfig.is_a?(Hash)

        if mobileconfig.is_a?(Hash)
          mobileconfig['PayloadContent'].each do |payload|
            payload['PayloadUUID'] = Puppet::Util::UuidV5.from_hash(payload) unless payload.key?('PayloadUUID')
            payload['PayloadUUID'] = payload['PayloadUUID'].upcase if payload['PayloadUUID'].match(context.type.attributes[:uuid][:format])
          end

          unless mobileconfig.key?('PayloadUUID')
            mobileconfig['PayloadUUID'] = resource.key?(:uuid) ? resource[:uuid] : Puppet::Util::UuidV5.from_hash(mobileconfig) # rubocop:disable Metrics/BlockNesting
          end
          resource[:uuid] = mobileconfig['PayloadUUID'] unless resource.key?(:uuid)
          mobileconfig['PayloadUUID'] = mobileconfig['PayloadUUID'].upcase if mobileconfig['PayloadUUID'].match(context.type.attributes[:uuid][:format])

          resource[:mobileconfig] = resource[:mobileconfig].is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive) ? Puppet::Pops::Types::PSensitiveType::Sensitive.new(mobileconfig) : mobileconfig
        end
      end

      resource[:uuid] = resource[:uuid].upcase if resource.key?(:uuid) && resource[:uuid].match(context.type.attributes[:uuid][:format])
    end
  end

  def get(context)
    profiles_xml = Puppet::Util::Execution.execute(['/usr/bin/profiles', 'show', '-type', 'configuration', '-output', 'stdout-xml'])
    profiles_hash = Puppet::Util::Plist.parse_plist(profiles_xml)

    resources = []
    unless profiles_hash.nil? || (profiles = profiles_hash.values[0]).nil?
      profiles.each do |profile|
        resource = {
          ensure: 'present',
          name: profile['ProfileIdentifier'],
          uuid: profile['ProfileUUID'].match(context.type.attributes[:uuid][:format]) ? profile['ProfileUUID'].upcase : profile['ProfileUUID'],
          profile: profile,
        }
        resources.push(resource)
      end
    end
    resources
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
    create_or_update(context, name, should)
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
    create_or_update(context, name, should)
  end

  def create_or_update(context, name, should)
    return context.err("Invalid resource '#{name}' because 'mobileconfig' is missing") unless should.key?(:mobileconfig)
    mobileconfig = should[:mobileconfig].is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive) ? should[:mobileconfig].unwrap : should[:mobileconfig]
    return context.err("Invalid resource '#{name}' because 'mobileconfig' has wrong format") unless mobileconfig.is_a?(Hash)
    return context.err("Invalid resource '#{name}' because name in property and identifier in mobileconfig differ") if name != mobileconfig['PayloadIdentifier']
    return context.err("Invalid resource '#{name}' because UUID in property and mobileconfig differ") if should[:uuid] != mobileconfig['PayloadUUID']

    dir_path = File.expand_path(File.join(Puppet[:vardir], 'mobileconfigs'))
    file_name = name
    file_path = File.join(dir_path, file_name + '.mobileconfig')
    FileUtils.mkdir(dir_path, mode: 0o600) unless Dir.exist?(dir_path)
    Puppet::Util::Plist.write_plist_file(mobileconfig, file_path)
    FileUtils.chmod(0o600, file_path)

    if should.key?(:certificate)
      if should[:encrypt] == true
        # /usr/libexec/mdmclient encrypt "encryptprofiles.vanagandr42.com" example.mobileconfig
        Puppet::Util::Execution.execute(['/usr/libexec/mdmclient', 'encrypt', should[:certificate], file_path])
        FileUtils.rm(file_path)
        file_name += '.encrypted'
        file_path = File.join(dir_path, file_name + '.mobileconfig')
        return context.err("Encryption failed for resource '#{name}'") unless File.exist?(file_path)
        FileUtils.chmod(0o600, file_path)
      end

      # /usr/bin/security cms -S -N "encryptprofiles.vanagandr42.com" -i example.encrypted.mobileconfig -o example.encrypted.signed.mobileconfig
      file_out_path = File.join(dir_path, file_name + '.signed.mobileconfig')
      Puppet::Util::Execution.execute(['/usr/bin/security', 'cms', '-S', '-N', should[:certificate], '-i', file_path, '-o', file_out_path])
      FileUtils.rm(file_path)
      file_name += '.signed'
      file_path = File.join(dir_path, file_name + '.mobileconfig')
      return context.err("Signing failed for resource '#{name}'") unless File.exist?(file_path)
      FileUtils.chmod(0o600, file_path)
    end

    Puppet::Util::Execution.execute(['/usr/bin/profiles', 'install', '-type', 'configuration', '-path', file_path])
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")

    dir_path = File.expand_path(File.join(Puppet[:vardir], 'mobileconfigs'))
    ['.mobileconfig', '.signed.mobileconfig', '.encrypted.signed.mobileconfig'].each do |suffix|
      file_path = File.join(dir_path, name + suffix)
      FileUtils.rm(file_path) if File.exist?(file_path)
    end

    Puppet::Util::Execution.execute(['/usr/bin/profiles', 'remove', '-type', 'configuration', '-identifier', name])
  end
end
