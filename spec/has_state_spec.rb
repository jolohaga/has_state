require File.dirname(__FILE__) + '/spec_helper.rb'

describe "State" do
  before(:each) do
    @state = mock('State')
    add_stubs(@state, :id => 1, :state => 'State1', :recorded_at => Time.now, :stateful_entity_id => 1, :stateful_entity_type => 'Test', :create_at => Time.now, :upated_at => Time.now)
  end
end