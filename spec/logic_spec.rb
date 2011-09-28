require 'helper'

def create_logics(dict={}, opt={})
  [Logic.new(dict, opt), Pure::Logic.new(dict, opt)]
end

describe Dat::Logic do
  include Dat

  context "#perturb" do
    before(:all) do
      @dict = Dict.new
    end

    it "should behave the same for C and pure Ruby versions" do
      log, plog = create_logics(@dict)
      log.perturb('DAT').sort_by(&:get).should == plog.perturb('DAT').sort_by(&:get)
      log.perturb('WALKED').sort_by(&:get).should == plog.perturb('WALKED').sort_by(&:get)
    end

    it "should filter out values that are in the 'used' blacklist" do
      log, plog = create_logics(@dict)
      used = {'CAT' => true, 'BAT' => true, 'FAT' => true, 'SAT' => true, 'MAT' => true, 'DAB' => true}
      log.perturb('DAT', used).map(&:get).should_not include(used.keys)
      plog.perturb('DAT', used).map(&:get).should_not include(used.keys)
    end

    it "should include tranposed words if the :transpose option is set" do
      log, plog = create_logics(@dict, :transpose => true, :min_size => 2)
      #log.perturb('AB').map(&:get).should include('BA')
      plog.perturb('AB').map(&:get).should include('BA')
    end

    it "should not include transposed words by default" do
      log, plog = create_logics(@dict)
      log.perturb('AB').map(&:get).should_not include('BA')
      plog.perturb('AB').map(&:get).should_not include('BA')
    end

    it "should not add letters if :add is not set" do
      log, plog = create_logics(@dict, :add => false)
      log.perturb('DAT').map(&:get).should_not include('DATE')
      plog.perturb('DAT').map(&:get).should_not include('DATE')
    end

    it "should not replace letters if :replace is not set" do
      log, plog = create_logics(@dict, :replace => false)
      log.perturb('DAT').map(&:get).should_not include('DAY')
      plog.perturb('DAT').map(&:get).should_not include('DAY')
    end

    it "should not delete letters if :delete is not set" do
      log, plog = create_logics(@dict, :delete => false)
      log.perturb('DAT').map(&:get).should_not include('AT')
      plog.perturb('DAT').map(&:get).should_not include('AT')
    end

    it "should not allow words shorter than :min_size" do
      log, plog = create_logics(@dict, :min_size => 4)
      log.perturb('DAT').map(&:get).should_not include('DAY')
      plog.perturb('DAT').map(&:get).should_not include('DAY')
    end
  end

  context "#damlev" do
    it "should correctly compute the Damaeu-Levenshtein distance between two strings" do
      log, plog = create_logics
      log.damlev('CA', 'ABC').should ==  2
      plog.damlev('CA', 'ABC').should ==  2
      log.damlev('TEUSDAY', 'TUESDAY').should == 1
      plog.damlev('TEUSDAY', 'TUESDAY').should == 1
      log.damlev('TEUSDAY', 'THRUSDAY').should == 2
      plog.damlev('TEUSDAY', 'THRUSDAY').should == 2
      log.damlev('TUESDAY', 'SOMETHING').should == 8
      plog.damlev('TUESDAY', 'SOMETHING').should == 8
    end
  end

  context "#leven" do
    it "should correctly compute the Levenshtein distance between two strings" do
      log, plog = create_logics
      log.leven('kitten', 'sitting').should ==  3
      plog.leven('kitten', 'sitting').should ==  3
      log.leven('xyzzy', 'hellosmal').should == 9
      plog.leven('xyzzy', 'hellosmal').should == 9
    end
  end

  context "#jaro_winkler" do
    it "should correctly implement the Jaro-Winkler function for two strings" do
      delta = 0.001
      log, plog = create_logics
      log.jaro_winkler('MARTHA', 'MARHTA').should be_within(delta).of(0.961)
      plog.jaro_winkler('MARTHA', 'MARHTA').should be_within(delta).of(0.961)
      log.jaro_winkler('DWAYNE', 'DUANE').should be_within(delta).of(0.84)
      plog.jaro_winkler('DWAYNE', 'DUANE').should be_within(delta).of(0.84)
      log.jaro_winkler('DIXON', 'DICKSONX').should be_within(delta).of(0.813)
      plog.jaro_winkler('DIXON', 'DICKSONX').should be_within(delta).of(0.813)
      log.jaro_winkler('DIXON', 'DIXON').should be_within(delta).of(1.0)
      plog.jaro_winkler('DIXON', 'DIXON').should be_within(delta).of(1.0)
    end
  end

end

