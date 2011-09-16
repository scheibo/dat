require 'helper'

describe Dat::Logic do
  include Dat

  context "#perturb" do
    before(:all) do
      @dict = Dict.new
    end

    ## need to try all permutations of options

    it "should behave the same for c and pure versions" do
      Logic.perturb('DAT', @dict).sort_by(&:get).should == Pure::Logic.perturb('DAT', @dict).sort_by(&:get)
      Logic.perturb('WALKED', @dict).sort_by(&:get).should == Pure::Logic.perturb('WALKED', @dict).sort_by(&:get)
    end

    it "should behave the same for upper and lower case" do
      Logic.perturb('DAT', @dict).should == Logic.perturb('dat', @dict)
      Pure::Logic.perturb('DAT', @dict).should == Pure::Logic.perturb('dat', @dict)
    end
  end

  context "#damlev" do
    it "should return the correct answers" do
      Logic.damlev('CA', 'ABC').should ==  2
      Pure::Logic.damlev('CA', 'ABC').should ==  2
      Logic.damlev('TEUSDAY', 'TUESDAY').should == 1
      Pure::Logic.damlev('TEUSDAY', 'TUESDAY').should == 1
      Logic.damlev('TEUSDAY', 'THRUSDAY').should == 2
      Pure::Logic.damlev('TEUSDAY', 'THRUSDAY').should == 2
      Logic.damlev('TUESDAY', 'SOMETHING').should == 8
      Pure::Logic.damlev('TUESDAY', 'SOMETHING').should == 8
    end
  end

  context "#leven" do
    it "should work correctly" do
      Logic.leven('kitten', 'sitting').should ==  3
      Pure::Logic.leven('kitten', 'sitting').should ==  3
      Logic.leven('xyzzy', 'hellosmal').should == 9
      Pure::Logic.leven('xyzzy', 'hellosmal').should == 9
    end
  end

  context "#jaro_winkler" do
    it "should work correctly" do
      delta = 0.001
      #Logic.jaro_winkler('MARTHA', 'MARHTA').should == 0.961
      Pure::Logic.jaro_winkler('MARTHA', 'MARHTA').should be_within(delta).of(0.961)
      #Logic.jaro_winkler('DWAYNE', 'DUANE').should == 0.84
      Pure::Logic.jaro_winkler('DWAYNE', 'DUANE').should be_within(delta).of(0.84)
      #Logic.jaro_winkler('DIXON', 'DICKSONX').should ==  0.813
      Pure::Logic.jaro_winkler('DIXON', 'DICKSONX').should be_within(delta).of(0.813)
      #Logic.jaro_winkler('DIXON', 'DIXON').should ==  1.0
      Pure::Logic.jaro_winkler('DIXON', 'DIXON').should be_within(delta).of(1.0)
    end
  end

end

