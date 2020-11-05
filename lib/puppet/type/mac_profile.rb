# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'mac_profile',
  docs: <<-EOS,
@summary Basic functionality to manage macOS profiles.
@example
mac_profile { 'com.vanagandr42.wifi.example':
  ensure       => present,
  mobileconfig => 'profile/mobileconfig/com.vanagandr42.wifi.example.epp'
}

This type provides Puppet with the capabilities to manage mobileconfigs under macOS. Because a mobileconfig cannot
 be extracted again completely from the system (e.g. passwords, certificates), the UUID is used to indicate changes:
 If the UUID given or computed from the mobileconfig is different from the one in the profile in the system, the mobileconfig
 is imported. Else no change is done.

If Puppet runs in priviliged mode, this type manages device profiles. If Puppet runs in unprivileged mode, it manages
 user profiles. User profiles can only be created if the user is logged in and authenticates as an Administrator. From
 Big Sur on profiles cannot be created. They are saved instead to disk and must be imported manually via the preference pane.
EOS
  features: ['canonicalize'],
  attributes: {
    ensure: {
      type:    'Enum[present, absent]',
      desc:    'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type:      'Pattern[/^[a-zA-Z0-9][a-zA-Z0-9\-\.]+[a-zA-Z0-9]$/]',
      desc:      'Unique identifier of the profile you want to manage.',
      behaviour: :namevar,
    },
    mobileconfig: {
      type:      'String',
      desc:      'Content of the profile in mobileconfig xml plist format.',
      behaviour: :parameter,
    },
    uuid: {
      type:   'String',
      desc:   'PayloadUUID of the the profile. It is computed from the checksum of the mobileconfig if absent. '\
                'A mobileconfig is only imported if the UUID is different from the one in the current profile.',
      format: %r{^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$},
    },
    profile: {
      type:      'Hash',
      desc:      'Content of the profile as reported by the system.',
      behaviour: :read_only,
    },
  },
)
