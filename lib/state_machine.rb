module StateMachine
  
  class UndefinedTransition < NotImplementedError
  end
  
  def self.included(base)
    base.send(:include, StateMachine::EventDrivenNonDeterministic)
  end
  
  # A couple of utilities for converting between names and symbols.  Assumes
  # names are human friendly titleized strings and symbols are snakecased.
  def name_to_symbol(name)
    name.downcase.gsub(/ /, "_").to_sym
  end
  
  def symbol_to_name(symbol)
    symbol.to_s.titleize
  end
  
  module EventDrivenNonDeterministic
    def self.included(base)
      base.extend StateMethods
    end

    module StateMethods
      
      # SomeStatefulModel.has_state
      #
      # Added to some_stateful_model.rb will create a has_many association with the State model.
      #
      def has_state
        unless included_modules.include? InstanceMethods
          extend ClassMethods
          include InstanceMethods
        end
        write_inheritable_attribute :states, []
        write_inheritable_attribute :transitions, {}
        write_inheritable_attribute :initial_state, []
        
        class_inheritable_reader :initial_state
        
        has_many :states, :as => :stateful_entity, :dependent => :destroy
        
        after_create :set_initial_state, :run_initial_state_actions
      end
    end

    module ClassMethods
      
      # SomeStatefulModel.states or SomeStatefulModel.states(:state1, state2, ...)
      #
      # When invoked without arguments, returns the states that have been declared through
      # the SomeStatefulModel.state or SomeStatefulModel.event methods.
      #
      # When invoked with arguments, takes that argument as a list of states to declare.
      #
      def states(*states)
        return read_inheritable_attribute(:states) if states.empty?
        states.each do |state|
          state(state)
        end
      end
      
      # SomeStatefulModel.state
      #
      # Declares a state (stores it in the states array).  Not really needed except to declare a state as initial
      # since SomeStateModel.event will declare the states passed in through its transitions hash (:to, :from).
      #
      # In some_stateful_model.rb (made stateful by including the line 'has_state') add:
      #
      #   state :accepted, :initial => true
      #
      def state(state, options={}, &block)
        read_inheritable_attribute(:states) << state unless read_inheritable_attribute(:states).include? state
        read_inheritable_attribute(:initial_state) << state if options[:initial]
      end
      
      # SomeStatefulModel.event
      #
      # In some_stateful_model.rb (made stateful by including the line 'has_state') add:
      #
      #  event :accept, :to => :accepted, :from => [:submitted]
      #   # transitions (:to, :from) are required
      #
      # This will create the instance method SomeStatefulModel#accept!
      #
      def event(action, transitions, &block)
        transitions(:to => transitions[:to], :from => transitions[:from])
        states(transitions[:to],*transitions[:from])
        define_method("#{action.to_s}") {
          self.current_state = transitions[:to]
        }
        
        # Also a class method, 'accepted' will be created, returning all records currently in the accepted state.
        #
        self.instance_eval <<-EOC
          def #{transitions[:to]}
            self.find(:all).collect {|t| t.current_state}.select {|t| t.name == "#{transitions[:to].to_s.titleize}"}
          end
        EOC
      end
      
      # SomeStatefulModel.transitions or SomeStatefulModel.transitions(:to => :some_state, :from => [from state list])
      #
      # When invoked without arguments, returns the transitions that have been defined through
      # the SomeStatefulModel.event methods.
      #
      # When invoked with arguments, takes that argument as a hash of transitions to define.
      #
      def transitions(options={})
        return read_inheritable_attribute(:transitions) if options.empty?
        options[:from].each do |from|
          read_inheritable_attribute(:transitions)[from] ||= []
          read_inheritable_attribute(:transitions)[from] << options[:to]
        end
      end
    end

    module InstanceMethods
      def set_initial_state
        self.current_state = self.class.initial_state
      end
      
      # Intended to carry out a user defined Proc action when initial state is set.
      def run_initial_state_actions
        return true
      end
      
      def current_state
        return states.find(:first, :order => 'recorded_at DESC')
      end
      
      def current_state=(transition_to)
        if self.states.empty? || (!next_states.nil? && next_states.include?(transition_to))
          self.states << State.new(:name => "#{symbol_to_name(transition_to)}", :recorded_at => Time.now)
        else
          raise UndefinedTransition.new(true), "Transition from #{name_to_symbol(self.current_state.name)} to #{transition_to} is undefined.  Either the current state is terminal or you need to define this transition in the model class file #{self.class}.rb."
        end
      end
      
      def next_states
        self.class.transitions[name_to_symbol(self.current_state.name)]
      end
    end
  end
end