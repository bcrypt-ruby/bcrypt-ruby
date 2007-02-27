require File.join(File.dirname(__FILE__), "..", "spec_helper")

context "BCrypt" do
  specify "should calculate the optimal cost factor to fit in a specific time" do
    first = BCrypt.calibrate(100)
    second = BCrypt.calibrate(300)
    second.should >(first + 1)
  end
end