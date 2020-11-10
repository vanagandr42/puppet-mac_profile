# mac_profile

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with mac_profile](#setup)
    * [What mac_profile affects](#what-mac_profile-affects)
    * [Beginning with mac_profile](#beginning-with-mac_profile)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)

## Description

This module provides basic functionality for macOS profiles via the 
mobileconfig format. A mobileconfig which is created in Puppet (e.g. with a 
template) can be used to install, update and remove a profile on a macOS 
client.

## Setup

### What mac_profile affects

Apart from (obviously) installing and removing profiles, this module writes
the mobileconfig files to the Puppet cache directory (e.g. 
`/opt/puppetlabs/puppet/cache/mobileconfigs`). These files can be used to install
a profile manually if the `install` verb of the profiles command is not supported 
by macOS anymore (starting with Big Sur).

### Beginning with mac_profile

The basic step to install a profile is to provide the profile name and the 
mobileconfig string (e.g. using a template) as follows:
```ruby
mac_profile { 'com.acme.wifi' }
  ensure       => present,
  mobileconfig => epp('profile/module/com.acme.wifi.mobileconfig.epp'),
}
```

## Usage
One issue with profiles is that the original content of the mobileconfig file
cannot be extracted again completely from the client. It is obvious why when 
you consider passwords and keys which can be configured using profiles.

Therefore a workaround is needed to find out if the profile currently installed 
on the client is the same one as in the mobileconfig in the Puppet catalog. This module 
diverts the `PayloadUUID` in the mobileconfig to achieve that: If both are the 
same the profile is considered to be up-to-date, if they do not match the profile 
will be updated with the values in the mobileconfig.

There are three ways to manage the UUID:
* It can be defined in the mobileconfig as `PayloadUUID` (like it is normally 
done.)
* It can be defined in the Puppet resource using the `uuid` parameter. In this 
case `PayloadUUID` must be removed from the mobileconfig.
* It can be neither defined in the Puppet resource nor as `PayloadUUID` in the 
mobileconfig. Here the UUID is generated automatically from a checksum of the 
mobileconfig. This is the recommended method because changes in the 
mobileconfig are picked up automatically.

This module can be used both in priviliged and unprivileged mode:
* If Puppet runs in priviliged mode, this type manages device profiles. 
* If Puppet runs in unprivileged mode, it manages user profiles.

If the mobileconfig contains secrets like a password, it is a good idea to use 
the Sensitive data type:
```ruby
mac_profile { 'com.acme.wifi' }
  ensure       => present,
  mobileconfig => Sensitive(epp('profile/module/com.acme.wifi.mobileconfig.epp')),
}
```

If there is a suitable certificate in the client's keychain (public & private 
key), this can be used to sign the mobileconfig:
```ruby
mac_profile { 'com.acme.wifi' }
  ensure       => present,
  mobileconfig => epp('profile/module/com.acme.wifi.mobileconfig.epp'),
  certificate  => 'My Certificate'
}
```

Even encryption can be done:
```ruby
mac_profile { 'com.acme.wifi' }
  ensure       => present,
  mobileconfig => Sensitive(epp('profile/module/com.acme.wifi.mobileconfig.epp')),
  certificate  => 'My Certificate'
  encrypt      => true
}
```

## Limitations

This module relies on the macOS `profiles` command, which defines
eventually the user experience. An update might run depending on the 
environment:
* totally silent,
* require some user interaction like providing a password
* or fail altogether because a verb is no longer supported (e.g. in Big Sur)

The only fully automated way to manage profiles is through an MDM. Possibly the 
create/update/delete methods of the Puppet provider can be adapted to use a 
vendor specific MDM API instead of the macOS profiles command.
