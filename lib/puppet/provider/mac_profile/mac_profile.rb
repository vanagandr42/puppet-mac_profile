# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'

# Implementation for the mac_profile type using the Resource API.
class Puppet::Provider::MacProfile::MacProfile < Puppet::ResourceApi::SimpleProvider
  def initialize
    require 'puppet/util/plist'
    require 'puppet/util/execution'
    # require 'cfpropertylist'
  end

  def canonicalize(context, resources)
    resources.each do |resource|
      resource[:uuid] = resource[:uuid].upcase if !resource[:uuid].nil? && resource[:uuid].match(context.type.attributes[:uuid][:format])

      unless resource[:mobileconfig].nil?
        # TODO: transform mobileconfigstring to hash plist
        # TODO: set PayloadIdentifier to name if absent
        # TODO: if PayloadUUID is absent, compute uuid from mobileconfig and set it
        # TODO: if one or more of the PayloadUUID in payloads is absent, compute uuid from payload and set it
      end

      if resource[:ensure] == :present
        # TODO: PayloadIdentifier must be same as name
        # TODO: PayloadUUID must be same as uuid
      end
    end
  end

  def get(context)
    raw_profiles_xml = Puppet::Util::Execution.execute(['/usr/bin/profiles', 'show', '-type', 'configuration', '-output', 'stdout-xml'])
    raw_profiles_hash = Puppet::Util::Plist.parse_plist(raw_profiles_xml)

    profiles = []
    unless raw_profiles_hash.nil? || (raw_profiles = raw_profiles_hash.values[0]).nil?
      raw_profiles.each do |raw_profile|
        profile = {
          ensure: 'present',
          name: raw_profile['ProfileIdentifier'],
          uuid: raw_profile['ProfileUUID'].match(context.type.attributes[:uuid][:format]) ? raw_profile['ProfileUUID'].upcase : raw_profile['ProfileUUID'],
          profile: raw_profile,
        }
        profiles.push(profile)
      end
    end
    profiles
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
    create_or_update(context, name, should)
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
    create_or_update(context, name, should)
  end

  def create_or_update(_context, _name, _should)
    # context.notice("Creating or updating '#{name}' with #{should.inspect}")
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
  end
end
