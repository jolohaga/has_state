module StateMachine
  
  class UndefinedTransition < NotImplementedError
  end
  
  def self.included(base)
    base.send(:include, StateMachine::EventDrivenNonDeterministic)
  end
  
  class << self
    # A couple of utilities for converting between names and symbols.  Assumes
    # names are human friendly titleized strings and symbols are snakecased.
    def name_to_symbol(name)
      name.downcase.gsub(/ /, "_").to_sym
    end
    
    def symbol_to_name(symbol)
      symbol.to_s.titleize
    end
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
        write_inheritable_attribute :protected_states, []
        write_inheritable_attribute :transitions, {}
        write_inheritable_attribute :initial_state, []
        write_inheritable_attribute :precedences, {}
        
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
      #  event :accept!, :to => :accepted, :from => [:submitted]
      #   # transitions (:to, :from) are required
      #
      # This will create the instance method SomeStatefulModel#accept!
      #
      def event(action, transitions, &block)
        transitions(:to => transitions[:to], :from => transitions[:from])
        states(transitions[:to],*transitions[:from])
        define_method("#{action.to_s}") { |*options|
          datetime = options.shift || Time.now
          self.transition(transitions[:to],datetime)
        }
        
        # SomeStatefulModel#accepted? is created, returning true if the model's current state matches the method's name (in this case accepted?), false otherwise.
        #
        define_method("#{transitions[:to].to_s}?") {
          self.current_state.name == StateMachine.symbol_to_name(transitions[:to])
        }
        
        # Also SomeStatefulModel.accepted is created, returning all records currently in the accepted state.
        #
        self.instance_eval <<-EOC
          def #{transitions[:to]}(options = {})
            order = options[:order].nil? ? "" : "ORDER BY " + options[:order]
            #{self.to_s}.find_by_sql(
             "SELECT *
               FROM #{self.to_s.tableize}
               WHERE id IN
                 (SELECT stateful_entity_id
                   FROM states
                   WHERE states.id IN
                   (SELECT DISTINCT ON (stateful_entity_id) id
                     FROM states
                     WHERE stateful_entity_type = '#{self.to_s}'
                     ORDER BY stateful_entity_id DESC, precedence DESC)
                     AND precedence = #{precedences[transitions[:to]]})
              \#{order}")
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
      
      # SomeStatefulModel.precedences or SomeStatefulModel.precedences(:state1, state2, ...)
      #
      # Precedences are used to order states and are stored in the State#precedence attribute.
      #
      # When invoked without arguments, returns the precedences.
      #
      # When invoked with arguments, takes that argument as a list of precedences.
      #
      def precedences(*precedences)
        return read_inheritable_attribute(:precedences) if precedences.empty?
        i = -1
        precedences.each do |precedence|
          read_inheritable_attribute(:precedences)[precedence] = (i += 1)
        end
      end
      
      # SomeStatefulModel.protected_states or SomeStatefulModel.protected_states(:state1, state2, ...)
      #
      # Return or define a set of states.  Defined in order to protect a StatefulModel from destructive actions while in the protected state.
      #
      def protected_states(*states)
        return read_inheritable_attribute(:protected_states) if states.empty?
        states.each do |state|
          read_inheritable_attribute(:protected_states) << state
        end
      end
      
      def terminal_states
        transitions.values.flatten.collect {|k| (transitions[k] == nil) && k}.uniq.reject {|k| k == false}
      end
    end

    module InstanceMethods
      def set_initial_state
        self.transition(self.class.initial_state[0], Time.now)
      end
      
      # Intended to carry out a user defined Proc action when initial state is set.
      def run_initial_state_actions
        return true
      end
      
      def current_state
        if self.class.precedences.nil?  # Use recorded_at timestamps to find current state.
          return states.find(:first, :order => 'recorded_at DESC')
        else                            # Use precedences defined in stateful model class.
          return states.find(:first, :order => 'precedence DESC')
        end
      end
      
      def transition(transition_to,datetime=Time.now)
        if self.states.empty? || (!next_states.nil? && next_states.include?(transition_to))
          self.states << State.new(:name => "#{StateMachine.symbol_to_name(transition_to)}", :recorded_at => datetime, :precedence => self.class.precedences[transition_to])
        else
          raise UndefinedTransition.new(true), "Transition from #{StateMachine.name_to_symbol(self.current_state.name)} to #{transition_to} is undefined.  Either the current state is terminal or you need to define this transition in the model class file #{self.class}.rb."
        end
      end
            
      def next_states
        self.class.transitions[StateMachine.name_to_symbol(self.current_state.name)]
      end
      
      def terminal?
        self.class.terminal_states.include?(StateMachine.name_to_symbol(self.current_state.name))
      end
      
      def protected?
        self.class.protected_states.include?(StateMachine.name_to_symbol(self.current_state.name))
      end
    end
  end
  
  module Helpers
    def select_next_state(next_states, options = {})
      style = options[:style] || ""
      unless next_states.nil?
        return <<-EOC
          <p>
            #{content_tag(:label, "State<br/>", :style => style)}
            #{select('state','name',["Select state..."] + next_states.map {|s| s.to_s.gsub(/_/," ").titleize}.zip(next_states),{},:style => style)}
          </p>
          <p>
            #{content_tag(:label, "Date<br/>", :style => style)}
            #{datetime_select("state","recorded_at",{},:style => style)}
          </p>
        EOC
      end
    end
  end
end