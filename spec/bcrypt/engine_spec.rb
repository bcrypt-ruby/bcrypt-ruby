require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe "The BCrypt engine" do
  specify "should calculate the optimal cost factor to fit in a specific time" do
    first = BCrypt::Engine.calibrate(100)
    second = BCrypt::Engine.calibrate(400)
    expect(second).to be > first
  end
end

describe "Generating BCrypt salts" do

  specify "should produce strings" do
    expect(BCrypt::Engine.generate_salt).to be_an_instance_of(String)
  end

  specify "should produce random data" do
    expect(BCrypt::Engine.generate_salt).to_not equal(BCrypt::Engine.generate_salt)
  end

  specify "should raise a InvalidCostError if the cost parameter isn't numeric" do
    expect { BCrypt::Engine.generate_salt('woo') }.to raise_error(BCrypt::Errors::InvalidCost)
  end

  specify "should raise a InvalidCostError if the cost parameter isn't greater than 0" do
    expect { BCrypt::Engine.generate_salt(-1) }.to raise_error(BCrypt::Errors::InvalidCost)
  end
end

describe "Autodetecting of salt cost" do

  specify "should work" do
    expect(BCrypt::Engine.autodetect_cost("$2a$08$hRx2IVeHNsTSYYtUWn61Ou")).to eq 8
    expect(BCrypt::Engine.autodetect_cost("$2a$05$XKd1bMnLgUnc87qvbAaCUu")).to eq 5
    expect(BCrypt::Engine.autodetect_cost("$2a$13$Lni.CZ6z5A7344POTFBBV.")).to eq 13
  end

end

describe "Generating BCrypt hashes" do

  class MyInvalidSecret
    undef to_s
  end

  before :each do
    @salt = BCrypt::Engine.generate_salt(4)
    @password = "woo"
  end

  specify "should produce a string" do
    expect(BCrypt::Engine.hash_secret(@password, @salt)).to be_an_instance_of(String)
  end

  specify "should raise an InvalidSalt error if the salt is invalid" do
    expect { BCrypt::Engine.hash_secret(@password, 'nino') }.to raise_error(BCrypt::Errors::InvalidSalt)
  end

  specify "should raise an InvalidSecret error if the secret is invalid" do
    expect { BCrypt::Engine.hash_secret(MyInvalidSecret.new, @salt) }.to raise_error(BCrypt::Errors::InvalidSecret)
    expect { BCrypt::Engine.hash_secret(nil, @salt) }.not_to raise_error
    expect { BCrypt::Engine.hash_secret(false, @salt) }.not_to raise_error
  end

  specify "should call #to_s on the secret and use the return value as the actual secret data" do
    expect(BCrypt::Engine.hash_secret(false, @salt)).to eq BCrypt::Engine.hash_secret("false", @salt)
  end

  specify "should be interoperable with other implementations" do
    # test vectors from the OpenWall implementation <http://www.openwall.com/crypt/>
    test_vectors = [
      ["U*U", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.E5YPO9kmyuRGyh0XouQYb4YMJKvyOeW"],
      ["U*U*", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.VGOzA784oUp/Z0DY336zx7pLYAy0lwK"],
      ["U*U*U", "$2a$05$XXXXXXXXXXXXXXXXXXXXXO", "$2a$05$XXXXXXXXXXXXXXXXXXXXXOAcXxm9kjPGEMsLznoKqmqw7tc8WCx4a"],
      ["0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", "$2a$05$abcdefghijklmnopqrstuu", "$2a$05$abcdefghijklmnopqrstuu5s2v8.iXieOjg/.AySBTTZIIVFJeBui"],
      ["\xa3", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e"],
      ["\xff\xff\xa3", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e"],
      ["\xff\xff\xa3", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e"],
      ["\xff\xff\xa3", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.nqd1wy.pTMdcvrRWxyiGL2eMz.2a85."],
      ["\xff\xff\xa3", "$2b$05$/OK.fbVrR/bpIqNJ5ianF.", "$2b$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e"],
      ["\xa3", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq"],
      ["\xa3", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq"],
      ["\xa3", "$2b$05$/OK.fbVrR/bpIqNJ5ianF.", "$2b$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq"],
      ["1\xa3" "345", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi"],
      ["\xff\xa3" "345", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi"],
      ["\xff\xa3" "34" "\xff\xff\xff\xa3" "345", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi"],
      ["\xff\xa3" "34" "\xff\xff\xff\xa3" "345", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi"],
      ["\xff\xa3" "34" "\xff\xff\xff\xa3" "345", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.ZC1JEJ8Z4gPfpe1JOr/oyPXTWl9EFd."],
      ["\xff\xa3" "345", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.nRht2l/HRhr6zmCp9vYUvvsqynflf9e"],
      ["\xff\xa3" "345", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.nRht2l/HRhr6zmCp9vYUvvsqynflf9e"],
      ["\xa3" "ab", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.6IflQkJytoRVc1yuaNtHfiuq.FRlSIS"],
      ["\xa3" "ab", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.6IflQkJytoRVc1yuaNtHfiuq.FRlSIS"],
      ["\xa3" "ab", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.6IflQkJytoRVc1yuaNtHfiuq.FRlSIS"],
      ["\xd1\x91", "$2x$05$6bNw2HLQYeqHYyBfLMsv/O", "$2x$05$6bNw2HLQYeqHYyBfLMsv/OiwqTymGIGzFsA4hOTWebfehXHNprcAS"],
      ["\xd0\xc1\xd2\xcf\xcc\xd8", "$2x$05$6bNw2HLQYeqHYyBfLMsv/O", "$2x$05$6bNw2HLQYeqHYyBfLMsv/O9LIGgn8OMzuDoHfof8AQimSGfcSWxnS"],
      ["\xaa"*72+"chars after 72 are ignored as usual", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.swQOIzjOiJ9GHEPuhEkvqrUyvWhEMx6"],
      ["\xaa\x55"*36, "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.R9xrDjiycxMbQE2bp.vgqlYpW5wx2yy"],
      ["\x55\xaa\xff"*24, "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.9tQZzcJfm3uj2NvJ/n5xkhpqLrMpWCe"],
      ["", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.7uG0VCzI2bS7j6ymqJi9CdcdxiRTWNy"]
    ]
    for secret, salt, test_vector in test_vectors
      expect(BCrypt::Engine.hash_secret(secret, salt)).to eql(test_vector)
    end
  end
end
