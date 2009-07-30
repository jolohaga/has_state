class State < ActiveRecord::Base
  belongs_to :stateful_entity, :polymorphic => true
end
