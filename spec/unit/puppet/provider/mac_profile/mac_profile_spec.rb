# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::MacProfile')
require 'puppet/provider/mac_profile/mac_profile'

RSpec.describe Puppet::Provider::MacProfile::MacProfile do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:typedef) { instance_double('Puppet::ResourceApi::TypeDefinition', 'typedef') }

  before(:each) do
    allow(context).to receive(:type).with(no_args).and_return(typedef)
  end

  describe 'canonicalize(context, resources)' do
    it 'canonicalizes no resources' do
      provider.canonicalize(context, [])
    end
  end

  describe '#get' do
    it 'processes no profiles' do
      allow(typedef).to receive(:attributes).with(no_args).and_return(uuid: { format: %r{^.*$} })
      expect(Puppet::Util::Execution).to receive(:execute).with(array_including('/usr/bin/profiles', 'show')).and_return('')
      expect(provider.get(context)).to eq []
    end

    it 'processes profile' do
      path = File.expand_path File.join(File.dirname(__FILE__), '../../data', 'single_profile.plist')

      allow(typedef).to receive(:attributes).with(no_args).and_return(uuid: { format: %r{^.*$} })
      expect(Puppet::Util::Execution).to receive(:execute).with(array_including('/usr/bin/profiles', 'show')).and_return(File.read(path))
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
      path = File.expand_path File.join(File.dirname(__FILE__), '../../data', 'multiple_profiles.plist')

      allow(typedef).to receive(:attributes).with(no_args).and_return(uuid: { format: %r{^$} })
      expect(Puppet::Util::Execution).to receive(:execute).with(array_including('/usr/bin/profiles', 'show')).and_return(File.read(path))
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

  describe 'create(context, name, should)' do
    it 'creates the resource' do
      expect(context).to receive(:notice).with(%r{\ACreating 'a'})

      provider.create(context, 'a', name: 'a', ensure: 'present')
    end
  end

  describe 'update(context, name, should)' do
    it 'updates the resource' do
      expect(context).to receive(:notice).with(%r{\AUpdating 'foo'})

      provider.update(context, 'foo', name: 'foo', ensure: 'present')
    end
  end

  describe 'delete(context, name)' do
    it 'deletes the resource' do
      expect(context).to receive(:notice).with(%r{\ADeleting 'foo'})

      provider.delete(context, 'foo')
    end
  end
end
