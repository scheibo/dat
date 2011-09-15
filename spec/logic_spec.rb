require 'helper'

describe Dat::Logic do
  include Dat

  before(:all) do
    @d = Dict.new
  end

  it "should behave the same for c and pure versions" do
    Logic.perturb('WALKED', @d).should == Pure::Logic.perturb('WALKED', @d)
  end

  it "should behave the same for upper and lower case" do
    pending
  end
end

