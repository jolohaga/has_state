ActiveRecord::Base.send(:include, StateMachine)
ActionController::Base.helper(StateMachine::Helpers)