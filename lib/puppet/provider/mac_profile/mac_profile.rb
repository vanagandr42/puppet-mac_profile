# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/util/execution'
require 'puppet/util/uuid_v5'
require 'puppet/util/plist'

# Implementation for the mac_profile type using the Resource API.
class Puppet::Provider::MacProfile::MacProfile < Puppet::ResourceApi::SimpleProvider
  def canonicalize(context, resources)
    resources.each do |resource|
      unless resource[:mobileconfig].nil?
        resource[:mobileconfig] = Puppet::Util::Plist.parse_plist(resource[:mobileconfig]) if resource[:mobileconfig].is_a?(String)

        resource[:mobileconfig]['PayloadContent'].each do |payload|
          unless payload.key?('PayloadUUID')
            payload['PayloadUUID'] = Puppet::Util::UuidV5.from_hash(payload)
          end
          payload['PayloadUUID'] = payload['PayloadUUID'].upcase if payload['PayloadUUID'].match(context.type.attributes[:uuid][:format])
        end
        unless resource[:mobileconfig].key?('PayloadUUID')
          resource[:mobileconfig]['PayloadUUID'] = resource.key?(:uuid) ? resource[:uuid] : Puppet::Util::UuidV5.from_hash(resource[:mobileconfig])
        end
        unless resource.key?(:uuid)
          resource[:uuid] = resource[:mobileconfig]['PayloadUUID']
        end
        resource[:mobileconfig]['PayloadUUID'] = resource[:mobileconfig]['PayloadUUID'].upcase if resource[:mobileconfig]['PayloadUUID'].match(context.type.attributes[:uuid][:format])
      end

      resource[:uuid] = resource[:uuid].upcase if !resource[:uuid].nil? && resource[:uuid].match(context.type.attributes[:uuid][:format])
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
    return context.err("Invalid resource '#{name}' because 'mobileconfig' is missing") if should[:mobileconfig].nil?
    return context.err("Invalid resource '#{name}' because name in property and identifier in mobileconfig differ") if name != should[:mobileconfig]['PayloadIdentifier']
    return context.err("Invalid resource '#{name}' because UUID in property and mobileconfig differ") if should[:uuid] != should[:mobileconfig]['PayloadUUID']

    dir_path = File.expand_path(File.join(Puppet[:vardir], 'mobileconfigs'))
    file_path = File.join(dir_path, name + '.mobileconfig')
    FileUtils.mkdir(dir_path, mode: 0o600) unless Dir.exist?(dir_path)
    Puppet::Util::Plist.write_plist_file(should[:mobileconfig], file_path)
    FileUtils.chmod(0o600, file_path)

    if should.key?(:certificate)
      if should[:encrypt] == true
        # TODO: Encrypt mobileconfig, delete source
        ## /usr/libexec/mdmclient encrypt "encryptprofiles.vanagandr42.com" example.mobileconfig
      end

      # TODO: Sign mobileconfig, delete source
      ## /usr/bin/security cms -S -N "encryptprofiles.vanagandr42.com" -i example.encrypted.mobileconfig -o example.encrypted.signed.mobileconfig
    end

    return unless should[:mode] == :profiles
    # TODO: Execute profiles command if mode is set to profiles
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")

    # TODO: Create mobileconfig with file from name (+ encrypted/signed as supplement)
    # TODO: Execute profiles command if mode is set to profiles
  end
end
