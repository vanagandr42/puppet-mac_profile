# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/mac_profile'

RSpec.describe 'the mac_profile type' do
  it 'loads' do
    expect(Puppet::Type.type(:mac_profile)).not_to be_nil
  end
end
