require 'helper'

def a_to_h(ary)
  Hash[*ary.collect { |v| [v, true] }.flatten]
end

describe Dat::Logic do
  include Dat

  context "#perturb" do
    before(:all) do
      @dict = Dict.new
    end

    before(:each) do
      @log = Logic.new @dict, :min_size => 2
      @plog = Pure::Logic.new @dict, :min_size => 2
    end

    ## TODO need to try all permutations of options

    it "should behave the same for c and pure versions" do
      @log.perturb('DAT').sort_by(&:get).should == @plog.perturb('DAT').sort_by(&:get)
      @log.perturb('WALKED').sort_by(&:get).should == @plog.perturb('WALKED').sort_by(&:get)
    end

    it "should be able to ignore used words" do
      words = %w{BAT CAT EAT FAT GAT HAT KAT LAT MAT OAT PAT QAT RAT SAT TAT VAT WAT}
      @log.perturb('DAT', a_to_h(words)).map(&:get).should_not include(words)
      @plog.perturb('DAT', a_to_h(words)).map(&:get).should_not include(words)
    end

    it "should be able to deal with filtering out already seen values" do
      used = {'CAT' => true, 'BAT' => true, 'FAT' => true, 'SAT' => true, 'MAT' => true, 'DAB' => true}
      @log.perturb('DAT', used).sort_by(&:get).should == @plog.perturb('DAT', used).sort_by(&:get)
    end
  end

  context "#damlev" do
    before(:each) do
      @log = Logic.new @dict, :min_size => 2
      @plog = Pure::Logic.new @dict, :min_size => 2
    end

    it "should return the correct answers" do
      @log.damlev('CA', 'ABC').should ==  2
      @plog.damlev('CA', 'ABC').should ==  2
      @log.damlev('TEUSDAY', 'TUESDAY').should == 1
      @plog.damlev('TEUSDAY', 'TUESDAY').should == 1
      @log.damlev('TEUSDAY', 'THRUSDAY').should == 2
      @plog.damlev('TEUSDAY', 'THRUSDAY').should == 2
      @log.damlev('TUESDAY', 'SOMETHING').should == 8
      @plog.damlev('TUESDAY', 'SOMETHING').should == 8
    end
  end

  context "#leven" do
    before(:each) do
      @log = Logic.new @dict, :min_size => 2
      @plog = Pure::Logic.new @dict, :min_size => 2
    end

    it "should work correctly" do
      @log.leven('kitten', 'sitting').should ==  3
      @plog.leven('kitten', 'sitting').should ==  3
      @log.leven('xyzzy', 'hellosmal').should == 9
      @plog.leven('xyzzy', 'hellosmal').should == 9
    end
  end

  context "#jaro_winkler" do
    before(:each) do
      @log = Logic.new @dict, :min_size => 2
      @plog = Pure::Logic.new @dict, :min_size => 2
    end

    it "should work correctly" do
      delta = 0.001
      @log.jaro_winkler('MARTHA', 'MARHTA').should be_within(delta).of(0.961)
      @plog.jaro_winkler('MARTHA', 'MARHTA').should be_within(delta).of(0.961)
      @log.jaro_winkler('DWAYNE', 'DUANE').should be_within(delta).of(0.84)
      @plog.jaro_winkler('DWAYNE', 'DUANE').should be_within(delta).of(0.84)
      @log.jaro_winkler('DIXON', 'DICKSONX').should be_within(delta).of(0.813)
      @plog.jaro_winkler('DIXON', 'DICKSONX').should be_within(delta).of(0.813)
      @log.jaro_winkler('DIXON', 'DIXON').should be_within(delta).of(1.0)
      @plog.jaro_winkler('DIXON', 'DIXON').should be_within(delta).of(1.0)
    end
  end

end

