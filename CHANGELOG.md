# Changelog

All notable changes to this project will be documented in this file.

## Release 1.1.0

**Features**
- Error messages from `profiles` and `security` commands are now integrated into Puppet error messages
- The `mdmclient`command has been removed. Encryption is now done using Ruby OpenSSL. This is more secure because the unencrypted payload is now never written to disk.

## Release 1.0.1

**Bugfixes**
- Syntax corrections for some examples in the README
