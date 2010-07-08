# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__)
$LOAD_PATH << File.join(File.dirname(__FILE__), "/../lib")
require 'rubygems'
require 'active_record'
require 'action_controller'
require 'rspec/rails'
require 'state_machine'
require 'nulldb_rspec'
include NullDB::RSpec::NullifiedDatabase

ActiveRecord::Base.send(:include, StateMachine)
ActionController::Base.helper(StateMachine::Helpers)
ActiveRecord::Base.establish_connection :adapter => :nulldb

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
end