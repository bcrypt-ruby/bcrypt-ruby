require File.join(File.dirname(__FILE__), "..", "spec_helper")

context "Generating BCrypt salts" do
  include BCrypt::Internals
  
  specify "should produce strings" do
    _bc_salt.should be_an_instance_of(String)
  end
  
  specify "should produce random data" do
    _bc_salt.should_not equal(_bc_salt)
  end
  
  specify "should raise a InvalidCostError if the cost parameter isn't numeric" do
    lambda { _bc_salt('woo') }.should raise_error(BCrypt::Errors::InvalidCost)
  end
end

context "Generating BCrypt hashes" do
  include BCrypt::Internals
  
  setup do
    @salt = _bc_salt
    @password = "woo"
  end
  
  specify "should produce a string" do
    _bc_crypt(@password, @salt).should be_an_instance_of(String)
  end
  
  specify "should raise an InvalidSaltError if the salt is invalid" do
    lambda { _bc_crypt(@password, 'nino') }.should raise_error(BCrypt::Errors::InvalidSalt)
  end
  
  specify "should be interoperable with other implementations" do
    # test vectors from the OpenWall implementation <http://www.openwall.com/crypt/>
    test_vectors = [
      ["U*U", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.E5YPO9kmyuRGyh0XouQYb4YMJKvyOeW"],
      ["U*U*", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.VGOzA784oUp/Z0DY336zx7pLYAy0lwK"],
      ["U*U*U", "$2a$05$XXXXXXXXXXXXXXXXXXXXXO", "$2a$05$XXXXXXXXXXXXXXXXXXXXXOAcXxm9kjPGEMsLznoKqmqw7tc8WCx4a"],
      ["", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.7uG0VCzI2bS7j6ymqJi9CdcdxiRTWNy"],
      ["0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", "$2a$05$abcdefghijklmnopqrstuu", "$2a$05$abcdefghijklmnopqrstuu5s2v8.iXieOjg/.AySBTTZIIVFJeBui"]
    ]
    for secret, salt, test_vector in test_vectors
      _bc_crypt(secret, salt).should eql(test_vector)
    end
  end
end