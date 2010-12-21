require 'ffi'

module BCrypt
  class Engine
    extend FFI::Library
    ffi_lib File.expand_path("../bcrypt", __FILE__)

    BCRYPT_MAXSALT = 16
    BCRYPT_SALT_OUTPUT_SIZE = (7 + (BCRYPT_MAXSALT * 4 + 2) / 3 + 1)
    BCRYPT_OUTPUT_SIZE = 128

    attach_function :ruby_bcrypt, [:buffer_out, :string, :string], :string
    attach_function :ruby_bcrypt_gensalt, [:buffer_out, :uint8, :uint8], :string

    def self.__bc_salt(cost, seed)
      salt = FFI::MemoryPointer.new(:pointer, BCRYPT_SALT_OUTPUT_SIZE)
      ruby_bcrypt_gensalt(salt, cost, seed)
      salt.read_string
    end


    def self.__bc_crypt(key, salt, cost)
      key ||= ""
      output = FFI::MemoryPointer.new(:pointer, BCRYPT_OUTPUT_SIZE)
      out = ruby_bcrypt(output, key, salt)
      return output.read_string if out and out.any?
      nil
    end
  end
end

