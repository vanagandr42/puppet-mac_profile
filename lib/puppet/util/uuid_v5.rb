require 'digest/sha1'

# A stand-alone module to claculate a v5 uuid from an integer, string, hash or array
module Puppet::Util::UuidV5
  class << self
    PROFILE_NAMESPACE = '3BC0480C-FDCA-4351-AFD1-D7D6CCAD24EA'.freeze
    HASH_CLASS = Digest::SHA1
    VERSION = 5

    def from_hash(hash)
      generate_uuid(PROFILE_NAMESPACE, sigflat(hash))
    end

    private

    def sigflat(object)
      if object.class == Hash
        str = ''
        object.map { |key, value| "#{sigflat key}=>#{sigflat value}" }.sort.each { |value| str << value }
        str
      elsif object.class == Array
        str = ''
        object.map { |value| sigflat value }.sort.each { |value| str << value }
        str
      elsif object.class != String
        object.to_s << object.class.to_s
      else
        object
      end
    end

    def generate_uuid(uuid_namespace, name)
      hash = HASH_CLASS.new
      hash.update(uuid_namespace)
      hash.update(name)

      ary = hash.digest.unpack('NnnnnN')
      ary[2] = (ary[2] & 0x0FFF) | (VERSION << 12)
      ary[3] = (ary[3] & 0x3FFF) | 0x8000

      '%08x-%04x-%04x-%04x-%04x%08x' % ary
    end
  end
end
