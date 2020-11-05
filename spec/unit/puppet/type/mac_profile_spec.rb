# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/mac_profile'

RSpec.describe 'the mac_profile type' do
  it 'loads' do
    expect(Puppet::Type.type(:mac_profile)).not_to be_nil
  end

  context 'with name set' do
    it 'throws no error if name is a valid identifier' do
      expect {
        Puppet::Type.type(:mac_profile).new(
          name: 'com.vanagandr42.wifi.example',
        )
      }.not_to raise_error
    end

    it 'throws no error if name contains uppercase letters' do
      expect {
        Puppet::Type.type(:mac_profile).new(
          name: 'com.vanagandr42.Wifi-Example',
        )
      }.not_to raise_error
    end

    it 'throws an error if name starts with ´.´' do
      expect {
        Puppet::Type.type(:mac_profile).new(
          name: '.com.vanagandr42.wifi.example',
        )
      }.to raise_error Puppet::ResourceError
    end

    it 'throws an error if name contains ´_´' do
      expect {
        Puppet::Type.type(:mac_profile).new(
          name: 'com.vanagandr42.wifi_example',
        )
      }.to raise_error Puppet::ResourceError
    end
  end

  context 'with uuid set' do
    let(:name) { 'com.vanagandr42.wifi.example' }

    it 'throws no error if uuid is valid' do
      expect {
        Puppet::Type.type(:mac_profile).new(
          name: name,
          uuid: '06CF9449-3ED9-4249-AD28-55A0DAEC26DA',
        )
      }.not_to raise_error
    end

    it 'throws no error if uuid is lower case' do
      expect {
        Puppet::Type.type(:mac_profile).new(
          name: name,
          uuid: '06cf9449-3ed9-4249-ad28-55a0daec26da',
        )
      }.not_to raise_error
    end
  end
end
