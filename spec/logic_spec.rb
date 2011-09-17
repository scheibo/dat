require 'helper'

describe Dat::Logic do
  include Dat

  context "#perturb" do
    before(:all) do
      @dict = Dict.new
    end

    before(:each) do
      #@log = Logic.new
      @plog = Pure::Logic.new @dict, :min_size => 2
    end

    ## TODO need to try all permutations of options

    it "should behave the same for c and pure versions" do
      Logic.perturb('DAT', @dict).sort_by(&:get).should == @plog.perturb('DAT').sort_by(&:get)
      Logic.perturb('WALKED', @dict).sort_by(&:get).should == @plog.perturb('WALKED').sort_by(&:get)
    end

    it "should behave the same for upper and lower case" do
      Logic.perturb('DAT', @dict).should == Logic.perturb('dat', @dict)
      @plog.perturb('DAT').should == @plog.perturb('dat')
    end
  end

  context "#damlev" do
    before(:each) do
      #@log = Logic.new
      @plog = Pure::Logic.new @dict, :min_size => 2
    end

    it "should return the correct answers" do
      Logic.damlev('CA', 'ABC').should ==  2
      @plog.damlev('CA', 'ABC').should ==  2
      Logic.damlev('TEUSDAY', 'TUESDAY').should == 1
      @plog.damlev('TEUSDAY', 'TUESDAY').should == 1
      Logic.damlev('TEUSDAY', 'THRUSDAY').should == 2
      @plog.damlev('TEUSDAY', 'THRUSDAY').should == 2
      Logic.damlev('TUESDAY', 'SOMETHING').should == 8
      @plog.damlev('TUESDAY', 'SOMETHING').should == 8
    end
  end

  context "#leven" do
    before(:each) do
      #@log = Logic.new
      @plog = Pure::Logic.new @dict, :min_size => 2
    end

    it "should work correctly" do
      Logic.leven('kitten', 'sitting').should ==  3
      @plog.leven('kitten', 'sitting').should ==  3
      Logic.leven('xyzzy', 'hellosmal').should == 9
      @plog.leven('xyzzy', 'hellosmal').should == 9
    end
  end

  context "#jaro_winkler" do
    before(:each) do
      #@log = Logic.new
      @plog = Pure::Logic.new @dict, :min_size => 2
    end

    it "should work correctly" do
      delta = 0.001
      #Logic.jaro_winkler('MARTHA', 'MARHTA').should == 0.961
      @plog.jaro_winkler('MARTHA', 'MARHTA').should be_within(delta).of(0.961)
      #Logic.jaro_winkler('DWAYNE', 'DUANE').should == 0.84
      @plog.jaro_winkler('DWAYNE', 'DUANE').should be_within(delta).of(0.84)
      #Logic.jaro_winkler('DIXON', 'DICKSONX').should ==  0.813
      @plog.jaro_winkler('DIXON', 'DICKSONX').should be_within(delta).of(0.813)
      #Logic.jaro_winkler('DIXON', 'DIXON').should ==  1.0
      @plog.jaro_winkler('DIXON', 'DIXON').should be_within(delta).of(1.0)
    end
  end

end

