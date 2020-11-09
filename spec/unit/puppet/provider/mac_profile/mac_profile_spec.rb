# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::MacProfile')
require 'puppet/provider/mac_profile/mac_profile'

RSpec.describe Puppet::Provider::MacProfile::MacProfile do
  subject(:provider) { described_class.new }

  single_profile = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../data', 'single_profile.plist')))
  multiple_profiles = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../data', 'multiple_profiles.plist')))
  minimal_mobileconfig = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../data', 'minimal.mobileconfig')))
  minimal_without_uuid_mobileconfig = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../data', 'minimal_without_uuid.mobileconfig')))
  minimal_without_uuids_mobileconfig = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../data', 'minimal_without_uuids.mobileconfig')))
  minimal_with_lowercase_uuid_mobileconfig = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../data', 'minimal_with_lowercase_uuid.mobileconfig')))
  example_mobileconfig = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../data', 'example.mobileconfig')))
  example_reordered_mobileconfig = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../data', 'example_reordered.mobileconfig')))

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:typedef) { instance_double('Puppet::ResourceApi::TypeDefinition', 'typedef') }

  before(:each) do
    allow(context).to receive(:type).with(no_args).and_return(typedef)
    allow(typedef).to receive(:attributes).with(no_args).and_return(uuid: { format: %r{^.*$} })
    allow(FileUtils).to receive(:mkdir)
    allow(FileUtils).to receive(:chmod)
    allow(Dir).to receive(:exist?)
    allow(Puppet::Util::Execution).to receive(:execute)
    allow(Puppet::Util::Plist).to receive(:write_plist_file)
  end

  describe 'canonicalize(context, resources)' do
    it 'canonicalizes no resources' do
      expect(provider.canonicalize(context, [])).to eq []
    end

    it 'takes uuid from mobileconfig if no uuid property is defined' do
      resource = {
        ensure:       'present',
        name:         'com.vanagandr42.minimal',
        mobileconfig: minimal_with_lowercase_uuid_mobileconfig,
      }

      allow(typedef).to receive(:attributes).with(no_args).and_return(uuid: { format: %r{^$} })
      expect(provider.canonicalize(context, [resource])).to match_array(
        [
          a_hash_including(
            ensure:       'present',
            name:         'com.vanagandr42.minimal',
            mobileconfig: a_hash_including('PayloadUUID' => '228420c8-9d51-4171-bd98-a37a7e8906c1'),
            uuid:         '228420c8-9d51-4171-bd98-a37a7e8906c1',
          ),
        ],
      )
    end

    it 'takes uuid from mobileconfig if no uuid property is defined and capitalizes if format matches' do
      resource = {
        ensure:       'present',
        name:         'com.vanagandr42.minimal',
        mobileconfig: minimal_mobileconfig,
      }

      expect(provider.canonicalize(context, [resource])).to match_array(
        [
          a_hash_including(
            ensure:       'present',
            name:         'com.vanagandr42.minimal',
            mobileconfig: a_hash_including('PayloadUUID' => '228420C8-9D51-4171-BD98-A37A7E8906C1'),
            uuid:         '228420C8-9D51-4171-BD98-A37A7E8906C1',
          ),
        ],
      )
    end

    it 'takes uuid from uuid property if it is not defined in mobileconfig' do
      resource = {
        ensure:       'present',
        name:         'com.vanagandr42.minimal',
        mobileconfig: minimal_without_uuid_mobileconfig,
        uuid:         '7aa4c897-43d1-49f7-8f9d-394d671458aa',
      }

      allow(typedef).to receive(:attributes).with(no_args).and_return(uuid: { format: %r{^$} })
      expect(provider.canonicalize(context, [resource])).to match_array(
        [
          a_hash_including(
            ensure:       'present',
            name:         'com.vanagandr42.minimal',
            mobileconfig: a_hash_including('PayloadUUID' => '7aa4c897-43d1-49f7-8f9d-394d671458aa'),
            uuid:         '7aa4c897-43d1-49f7-8f9d-394d671458aa',
          ),
        ],
      )
    end

    it 'takes uuid from uuid property if it is not defined in mobileconfig and capitalizes if format matches' do
      resource = {
        ensure:       'present',
        name:         'com.vanagandr42.minimal',
        mobileconfig: minimal_without_uuid_mobileconfig,
        uuid:         '7aa4c897-43d1-49f7-8f9d-394d671458aa',
      }

      expect(provider.canonicalize(context, [resource])).to match_array(
        [
          a_hash_including(
            ensure:       'present',
            name:         'com.vanagandr42.minimal',
            mobileconfig: a_hash_including('PayloadUUID' => '7AA4C897-43D1-49F7-8F9D-394D671458AA'),
            uuid:         '7AA4C897-43D1-49F7-8F9D-394D671458AA',
          ),
        ],
      )
    end

    it 'generates uuid if uuid is not defined as property and in mobileconfig' do
      resource = {
        ensure:       'present',
        name:         'com.vanagandr42.minimal',
        mobileconfig: minimal_without_uuid_mobileconfig,
      }

      expect(provider.canonicalize(context, [resource])).to match_array(
        [
          a_hash_including(
            ensure:       'present',
            name:         'com.vanagandr42.minimal',
            mobileconfig: a_hash_including('PayloadUUID' => '60B33304-6EF1-5AE3-AE20-C587DCC94D70'),
            uuid:         '60B33304-6EF1-5AE3-AE20-C587DCC94D70',
          ),
        ],
      )
    end

    it 'generates payload uuid if uuid is not defined in mobileconfig' do
      resource = {
        ensure:       'present',
        name:         'com.vanagandr42.minimal',
        mobileconfig: minimal_without_uuids_mobileconfig,
        uuid:         'F16687CD-3530-457C-87A1-7EF7A9989D4C',
      }

      expect(provider.canonicalize(context, [resource])).to match_array(
        [
          a_hash_including(
            ensure:       'present',
            name:         'com.vanagandr42.minimal',
            mobileconfig:
              a_hash_including(
                'PayloadUUID'    => 'F16687CD-3530-457C-87A1-7EF7A9989D4C',
                'PayloadContent' => match_array([a_hash_including('PayloadUUID' => 'CB0EE02C-4FF8-5E6B-A433-3764A87FE148')]),
              ),
            uuid:         'F16687CD-3530-457C-87A1-7EF7A9989D4C',
          ),
        ],
      )
    end

    it 'generates all uuids if uuids are not defined in mobileconfig' do
      resource = {
        ensure:       'present',
        name:         'com.vanagandr42.minimal',
        mobileconfig: minimal_without_uuids_mobileconfig,
      }

      expect(provider.canonicalize(context, [resource])).to match_array(
        [
          a_hash_including(
            ensure:       'present',
            name:         'com.vanagandr42.minimal',
            mobileconfig:
              a_hash_including(
                'PayloadUUID'    => 'EE8C237B-568D-5119-AF5A-D2FF942D5F41',
                'PayloadContent' => match_array([a_hash_including('PayloadUUID' => 'CB0EE02C-4FF8-5E6B-A433-3764A87FE148')]),
              ),
            uuid:         'EE8C237B-568D-5119-AF5A-D2FF942D5F41',
          ),
        ],
      )
    end

    it 'checks a complex example' do
      resource = {
        ensure:       'present',
        name:         'com.vanagandr42.example',
        mobileconfig: example_mobileconfig,
      }

      expect(provider.canonicalize(context, [resource])).to match_array(
        [
          a_hash_including(
            ensure:       'present',
            name:         'com.vanagandr42.example',
            mobileconfig:
              a_hash_including(
                'PayloadUUID'    => 'FEBC2F47-C520-5DCE-A29B-FB5BCF6B3854',
                'PayloadContent' => match_array(
                  [
                    a_hash_including(
                      'PayloadIdentifier' => 'com.vanagandr42.example.wifi1',
                      'PayloadUUID'       => 'FB096D71-25B9-418B-82CB-FB9BD0707B23',
                    ),
                    a_hash_including(
                      'PayloadIdentifier' => 'com.vanagandr42.example.wifi2',
                      'PayloadUUID'       => 'F171D057-CEF8-5F3D-9338-4350EA131BC6',
                    ),
                    a_hash_including(
                      'PayloadIdentifier' => 'com.vanagandr42.example.payload3',
                      'PayloadUUID'       => 'C05EA2DF-AA6E-5040-9522-9009627506F3',
                    ),
                  ],
                ),
              ),
            uuid:         'FEBC2F47-C520-5DCE-A29B-FB5BCF6B3854',
          ),
        ],
      )
    end

    it 'checks the same complex example, but elements are ordered differently' do
      resource = {
        ensure:       'present',
        name:         'com.vanagandr42.example',
        mobileconfig: example_reordered_mobileconfig,
      }

      expect(provider.canonicalize(context, [resource])).to match_array(
        [
          a_hash_including(
            ensure:       'present',
            name:         'com.vanagandr42.example',
            mobileconfig:
              a_hash_including(
                'PayloadUUID'    => 'FEBC2F47-C520-5DCE-A29B-FB5BCF6B3854',
                'PayloadContent' => match_array(
                  [
                    a_hash_including(
                      'PayloadIdentifier' => 'com.vanagandr42.example.wifi1',
                      'PayloadUUID'       => 'FB096D71-25B9-418B-82CB-FB9BD0707B23',
                    ),
                    a_hash_including(
                      'PayloadIdentifier' => 'com.vanagandr42.example.wifi2',
                      'PayloadUUID'       => 'F171D057-CEF8-5F3D-9338-4350EA131BC6',
                    ),
                    a_hash_including(
                      'PayloadIdentifier' => 'com.vanagandr42.example.payload3',
                      'PayloadUUID'       => 'C05EA2DF-AA6E-5040-9522-9009627506F3',
                    ),
                  ],
                ),
              ),
            uuid:         'FEBC2F47-C520-5DCE-A29B-FB5BCF6B3854',
          ),
        ],
      )
    end
  end

  describe '#get' do
    it 'processes no profiles' do
      expect(Puppet::Util::Execution).to receive(:execute).with(array_including('/usr/bin/profiles', 'show')).and_return('')
      expect(provider.get(context)).to eq []
    end

    it 'processes profile' do
      expect(Puppet::Util::Execution).to receive(:execute).with(array_including('/usr/bin/profiles', 'show')).and_return(single_profile)
      expect(provider.get(context)).to match_array(
        [
          a_hash_including(
            ensure:  'present',
            name:    'com.vanagandr42.wifi.example',
            uuid:    '228420C8-9D51-4171-BD98-A37A7E8906C1',
            profile: a_hash_including(
              'ProfileIdentifier' => 'com.vanagandr42.wifi.example',
              'ProfileUUID'       => '228420c8-9d51-4171-BD98-A37A7E8906C1',
            ),
          ),
        ],
      )
    end

    it 'processes profiles' do
      allow(typedef).to receive(:attributes).with(no_args).and_return(uuid: { format: %r{^$} })
      expect(Puppet::Util::Execution).to receive(:execute).with(array_including('/usr/bin/profiles', 'show')).and_return(multiple_profiles)
      expect(provider.get(context)).to match_array(
        [
          a_hash_including(
            ensure:  'present',
            name:    'com.acmecorp.mdm',
            uuid:    '37afccc4-a33e-41eb-ba2c-2f243e05ee4a',
            profile: a_hash_including('ProfileIdentifier' => 'com.acmecorp.mdm'),
          ),
          a_hash_including(
            ensure:  'present',
            name:    'com.mdm.15fe5e90-20ea-4641-9262-6ef0d0449bfe.MyProfile11',
            uuid:    '98eca119-fb6f-4e8a-aac7-58e1582e007d',
            profile: a_hash_including('ProfileIdentifier' => 'com.mdm.15fe5e90-20ea-4641-9262-6ef0d0449bfe.MyProfile11'),
          ),
          a_hash_including(
            ensure:  'present',
            name:    'com.mdm.27087cd8-121c-4183-ab97-a7ee3c46ff51.Wifi',
            uuid:    '4f19fc5a-ce2c-4378-9483-5aaa743b1e47',
            profile: a_hash_including('ProfileIdentifier' => 'com.mdm.27087cd8-121c-4183-ab97-a7ee3c46ff51.Wifi'),
          ),
          a_hash_including(
            ensure:  'present',
            name:    'com.acmeengine.mdm.mac',
            uuid:    'com.acmeengine.mdm.mac',
            profile: a_hash_including('ProfileIdentifier' => 'com.acmeengine.mdm.mac'),
          ),
          a_hash_including(
            ensure:  'present',
            name:    'com.mdm.8e70980a-608d-42e2-a258-3623cb286aa4.MyProfile12',
            uuid:    'f2b86dc6-a491-4b79-924f-513eec981d5c',
            profile: a_hash_including('ProfileIdentifier' => 'com.mdm.8e70980a-608d-42e2-a258-3623cb286aa4.MyProfile12'),
          ),
        ],
      )
    end
  end

  # describe 'create(context, name, should)' do
  #   it 'creates the resource' do
  #     expect(context).to receive(:notice).with(%r{\ACreating 'a'})

  #     provider.create(context, 'a', name: 'a', ensure: 'present')
  #   end
  # end

  # describe 'update(context, name, should)' do
  #   it 'updates the resource' do
  #     expect(context).to receive(:notice).with(%r{\AUpdating 'foo'})

  #     provider.update(context, 'foo', name: 'foo', ensure: 'present')
  #   end
  # end

  describe 'create_or_update(context, name, should)' do
    it 'fails if no mobileconfig is defined' do
      should = {
        ensure: 'present',
        name:   'com.vanagandr42.minimal',
      }

      expect(context).to receive(:err)
      provider.create_or_update(context, 'com.vanagandr42.minimal', should)
    end

    it 'fails if name in resource and identifier in mobileconfig are not the same' do
      should = {
        ensure:       'present',
        name:         'com.vanagandr42.maximal',
        mobileconfig: {
          'PayloadIdentifier' => 'com.vanagandr42.minimal',
          'PayloadUUID'       => '228420C8-9D51-4171-BD98-A37A7E8906C1',
        },
        uuid:         '228420C8-9D51-4171-BD98-A37A7E8906C1',
      }

      expect(context).to receive(:err)
      provider.create_or_update(context, 'com.vanagandr42.maximal', should)
    end

    it 'fails if uuid in resource and mobileconfig are not the same' do
      should = {
        ensure:       'present',
        name:         'com.vanagandr42.minimal',
        mobileconfig: {
          'PayloadIdentifier' => 'com.vanagandr42.minimal',
          'PayloadUUID'       => '228420C8-9D51-4171-BD98-A37A7E8906C1',
        },
        uuid:         '68BB6A40-9AFA-49B0-9A2C-FD8DF7EAD24A',
      }

      expect(context).to receive(:err)
      provider.create_or_update(context, 'com.vanagandr42.minimal', should)
    end

    it 'succeeds if name & uuid in resource and mobileconfig are the same' do
      should = {
        ensure:       'present',
        name:         'com.vanagandr42.minimal',
        mobileconfig: {
          'PayloadIdentifier' => 'com.vanagandr42.minimal',
          'PayloadUUID'       => '228420C8-9D51-4171-BD98-A37A7E8906C1',
        },
        uuid:         '228420C8-9D51-4171-BD98-A37A7E8906C1',
      }

      provider.create_or_update(context, 'com.vanagandr42.minimal', should)
    end

    it 'succeeds to create a mobileconfig file' do
      should = {
        ensure:       'present',
        name:         'com.vanagandr42.minimal',
        mode:         :file,
        mobileconfig: {
          'PayloadIdentifier' => 'com.vanagandr42.minimal',
          'PayloadUUID'       => '228420C8-9D51-4171-BD98-A37A7E8906C1',
        },
        uuid:         '228420C8-9D51-4171-BD98-A37A7E8906C1',
      }

      expect(Dir).to receive(:exist?).with('/dev/null/mobileconfigs').and_return(false)
      expect(FileUtils).to receive(:mkdir).with('/dev/null/mobileconfigs', mode: 0o600)
      expect(Puppet::Util::Plist).to receive(:write_plist_file).with(
        a_hash_including('PayloadIdentifier' => 'com.vanagandr42.minimal'),
        '/dev/null/mobileconfigs/com.vanagandr42.minimal.mobileconfig',
      )
      expect(FileUtils).to receive(:chmod).with(0o600, '/dev/null/mobileconfigs/com.vanagandr42.minimal.mobileconfig')
      provider.create_or_update(context, 'com.vanagandr42.minimal', should)
    end
  end

  describe 'delete(context, name)' do
    it 'deletes the resource' do
      expect(context).to receive(:notice).with(%r{\ADeleting 'foo'})

      provider.delete(context, 'foo')
    end
  end
end
