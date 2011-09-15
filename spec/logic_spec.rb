require 'helper'

describe Dat::Logic do
  include Dat

  before(:all) do
    @dict = Dict.new
  end

  it "should behave the same for c and pure versions" do
    Logic.perturb('DAT', @dict).should == Pure::Logic.perturb('DAT', @dict)
    Logic.perturb('WALKED', @dict).should == Pure::Logic.perturb('WALKED', @dict)
  end

  it "should behave the same for upper and lower case" do
    Logic.perturb('DAT', @dict).should == Logic.perturb('dat', @dict)
    Pure::Logic.perturb('DAT', @dict).should == Pure::Logic.perturb('dat', @dict)
  end
end

