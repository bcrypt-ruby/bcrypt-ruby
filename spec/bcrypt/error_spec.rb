require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe "Errors" do

  shared_examples "StandardError" do
    it "is is rescued as a StandardError" do
      described_class.should < StandardError
    end
  end

  describe BCrypt::Errors::InvalidCost do
    it_behaves_like "StandardError"
  end

  describe BCrypt::Errors::InvalidHash do
    it_behaves_like "StandardError"
  end

  describe BCrypt::Errors::InvalidSalt do
    it_behaves_like "StandardError"
  end

  describe BCrypt::Errors::InvalidSecret do
    it_behaves_like "StandardError"
  end

end
