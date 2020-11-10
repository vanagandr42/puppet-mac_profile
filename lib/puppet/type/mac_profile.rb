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

This type provides Puppet with the capabilities to manage mobileconfigs under macOS. Because a mobileconfig cannot be extracted again completely from the system (e.g. passwords, certificates), the UUID is used to indicate changes: If the UUID given or calculated from the mobileconfig is different from the one in the profile in the system, the mobileconfig is imported. Else no change is done.

Mobileconfigs can be signed and encrypted. The certificate which is needed for that must be present in the keychain and accessible by the provider. E.g. this can be achieved by importing it via mobileconfig with ´AllowAllAppsAccess´ set to ´true´.

If Puppet runs in priviliged mode, this type manages device profiles. If Puppet runs in unprivileged mode, it manages user profiles. In both modes the mobileconfig files are created in the respective Puppet cache directory. Then the macOS profiles command is executed to process it.

The latter will be done silently or the user must confirm this by entering an administrator password. From Big Sur onward this will fail altogether. The only way here is to manually import the files from the Puppet cache directory. The only fully automated way to manage profiles is through an MDM. Possibly the provider's create/update/delete methods can be adapted to use a vendor specific MDM API instead of the macOS profiles command.
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
      type:      'Optional[Variant[Hash, String, Sensitive[Hash], Sensitive[String]]]',
      desc:      'Content of the profile in mobileconfig xml plist format. ´Sensitive´ type can be used when the '\
                  'mobileconfig contains secrets.',
      behaviour: :parameter,
    },
    uuid: {
      type:   'String',
      desc:   'PayloadUUID of the the profile. It is computed from the checksum of the mobileconfig if absent. '\
                'A mobileconfig is only imported if the UUID is different from the one in the current profile.',
      format: %r{^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$},
    },
    certificate: {
      type:      'Optional[String]',
      desc:      'Name of the certificate as shown in the keychain. Mobileconfig will be signed if defined.',
      behaviour: :parameter,
    },
    encrypt: {
      type:      'Boolean',
      desc:      'Whether to encrypt the mobileconfig. Fails if no certificate is defined.',
      behaviour: :parameter,
      default:   false,
    },
    profile: {
      type:      'Hash',
      desc:      'Content of the profile as reported by the system.',
      behaviour: :read_only,
    },
  },
)
