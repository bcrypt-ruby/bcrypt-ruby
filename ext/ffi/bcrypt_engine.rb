require 'ffi'

module BCrypt
  class Engine
    extend FFI::Library
    ffi_lib File.expand_path("../bcrypt.so", __FILE__)

    attach_function :ruby_bcrypt, [:string, :string], :string
    attach_function :ruby_bcrypt_gensalt, [:uint8, :uint8], :string

    def self.__bc_salt(cost, seed)
      salt = ruby_bcrypt_gensalt(cost, seed)
    end


    def self.__bc_crypt(key, salt, cost)
      out = ruby_bcrypt(key || "", salt)
      out && out.any? ? output : nil
    end
  end
end

