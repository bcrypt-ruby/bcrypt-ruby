require File.join(File.dirname(__FILE__), "..", "spec_helper")

context "The BCrypt engine" do
  specify "should calculate the optimal cost factor to fit in a specific time" do
    first = BCrypt::Engine.calibrate(100)
    second = BCrypt::Engine.calibrate(300)
    second.should >(first + 1)
  end
end

context "Generating BCrypt salts" do
  
  specify "should produce strings" do
    BCrypt::Engine.generate_salt.should be_an_instance_of(String)
  end
  
  specify "should produce random data" do
    BCrypt::Engine.generate_salt.should_not equal(BCrypt::Engine.generate_salt)
  end
  
  specify "should raise a InvalidCostError if the cost parameter isn't numeric" do
    lambda { BCrypt::Engine.generate_salt('woo') }.should raise_error(BCrypt::Errors::InvalidCost)
  end
  
  specify "should raise a InvalidCostError if the cost parameter isn't greater than 0" do
    lambda { BCrypt::Engine.generate_salt(-1) }.should raise_error(BCrypt::Errors::InvalidCost)
  end
end

context "Generating BCrypt hashes" do
  
  setup do
    @salt = BCrypt::Engine.generate_salt(4)
    @password = "woo"
  end
  
  specify "should produce a string" do
    BCrypt::Engine.hash(@password, @salt).should be_an_instance_of(String)
  end
  
  specify "should raise an InvalidSalt error if the salt is invalid" do
    lambda { BCrypt::Engine.hash(@password, 'nino') }.should raise_error(BCrypt::Errors::InvalidSalt)
  end
  
  specify "should raise an InvalidSecret error if the secret is invalid" do
    lambda { BCrypt::Engine.hash(nil, @salt) }.should_not raise_error(BCrypt::Errors::InvalidSecret)
    lambda { BCrypt::Engine.hash(false, @salt) }.should_not raise_error(BCrypt::Errors::InvalidSecret)
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
      BCrypt::Engine.hash(secret, salt).should eql(test_vector)
    end
  end
end