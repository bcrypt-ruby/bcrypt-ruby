# A wrapper for OpenBSD's bcrypt/crypt_blowfish password-hashing algorithm.

$: << "ext"
require "bcrypt_ext"
require "openssl"

# A Ruby library implementing OpenBSD's bcrypt()/crypt_blowfish algorithm for
# hashing passwords.
module BCrypt
  module Errors # :nodoc:
    # The salt parameter provided to bcrypt() is invalid.
    class InvalidSalt < Exception; end
    # The hash parameter provided to bcrypt() is invalid.
    class InvalidHash < Exception; end
    # The cost parameter provided to bcrypt() is invalid.
    class InvalidCost < Exception; end
  end
  
  # The default computational expense parameter.
  DEFAULT_COST = 10
  
  module Internals # :nodoc:
    # contains the C-level methods and other internally bits
    
    # Maximum length of salts.
    MAX_SALT_LENGTH = 16
    
    # Wrap this in some error checking otherwise it'll explode.
    def _bc_crypt(key, salt)
      if valid_salt?(salt)
        __bc_crypt(key, salt)
      else
        raise Errors::InvalidSalt.new("invalid salt")
      end
    end
    
    def _bc_salt(cost = DEFAULT_COST)
      if cost.to_i > 0
        __bc_salt(cost, OpenSSL::Random.random_bytes(MAX_SALT_LENGTH))
      else
        raise Errors::InvalidCost.new("cost must be numeric and > 0")
      end
    end
    
    def valid_salt?(s)
      s =~ /^\$[0-9a-z]{2,}\$[0-9]{2,}\$[A-Za-z0-9\.\/]{22,}$/
    end
  end
  
  # Returns the cost factor which will result in computation times less than +upper_time_limit_in_ms+.
  # 
  # Example:
  # 
  #   BCrypt.calibrate(200)  #=> 10
  #   BCrypt.calibrate(1000) #=> 12
  # 
  #   # should take less than 200ms
  #   BCrypt::Password.create("woo", :cost => 10)
  # 
  #   # should take less than 1000ms
  #   BCrypt::Password.create("woo", :cost => 12)
  def self.calibrate(upper_time_limit_in_ms)
    40.times do |i|
      start_time = Time.now
      Password.create("testing testing", :cost => i+1)
      end_time = Time.now - start_time
      return i if end_time * 1_000 > upper_time_limit_in_ms
    end
  end
  
  # A password management class which allows you to safely store users' passwords and compare them.
  # 
  # Example usage:
  # 
  #   include BCrypt
  # 
  #   # hash a user's password  
  #   @password = Password.create("my grand secret")
  #   @password #=> "$2a$10$GtKs1Kbsig8ULHZzO1h2TetZfhO4Fmlxphp8bVKnUlZCBYYClPohG"
  # 
  #   # store it safely
  #   @user.update_attribute(:password, @password)
  # 
  #   # read it back
  #   @user.reload!
  #   @db_password = Password.new(@user.password)
  # 
  #   # compare it after retrieval
  #   @db_password == "my grand secret" #=> true
  #   @db_password == "a paltry guess"  #=> false
  # 
  class Password < String
    # The hash portion of the stored password hash.
    attr_reader :hash
    # The salt of the store password hash (including version and cost).
    attr_reader :salt
    # The version of the bcrypt() algorithm used to create the hash.
    attr_reader :version
    # The cost factor used to create the hash.
    attr_reader :cost
    
    class << self
      # Hashes a secret, returning a BCrypt::Password instance. Takes an optional <tt>:cost</tt> option, which is a
      # logarithmic variable which determines how computational expensive the hash is to calculate (a <tt>:cost</tt> of
      # 4 is twice as much work as a <tt>:cost</tt> of 3). The higher the <tt>:cost</tt> the harder it becomes for
      # attackers to try to guess passwords (even if a copy of your database is stolen), but the slower it is to check
      # users' passwords.
      # 
      # Example:
      # 
      #   @password = BCrypt::Password.create("my secret", :cost => 13)
      def create(secret, options = { :cost => DEFAULT_COST })
        Password.new(_bc_crypt(secret, _bc_salt(options[:cost])))
      end
    private
      include Internals
    end
    
    # Initializes a BCrypt::Password instance with the data from a stored hash.
    def initialize(raw_hash)
      if valid_hash?(raw_hash)
        self.replace(raw_hash)
        @version, @cost, @salt, @hash = split_hash(self)
      else
        raise Errors::InvalidHash.new("invalid hash")
      end
    end
    
    alias_method :exactly_equals, :==
    
    # Compares a potential secret against the hash. Returns true if the secret is the original secret, false otherwise.
    def ==(secret)
      self.exactly_equals(self.class._bc_crypt(secret, @salt))
    end
    
  private
    # Returns true if +h+ is a valid hash.
    def valid_hash?(h)
      h =~ /^\$[0-9a-z]{2}\$[0-9]{2}\$[A-Za-z0-9\.\/]{53}$/
    end
    
    # call-seq:
    #   split_hash(raw_hash) -> version, cost, salt, hash
    # 
    # Splits +h+ into version, cost, salt, and hash and returns them in that order.
    def split_hash(h)
      b, v, c, mash = h.split('$')
      return v, c.to_i, h[0, 29], mash[-31, 31]
    end
  end
end