require File.join(File.dirname(__FILE__), "/../spec_helper")

module HasState
  class StatefulModel < ActiveRecord::Base
    has_state
  end
  describe HasState do
    before(:each) do
      @state = State.new
    end
    
    it "should work" do
      @state.recorded_at
    end
  end
end