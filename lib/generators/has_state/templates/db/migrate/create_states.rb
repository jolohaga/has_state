class CreateStates < ActiveRecord::Migration
  def self.up
    create_table :states do |t|
      t.string :name
      t.datetime :recorded_at
      t.integer :stateful_entity_id
      t.string :stateful_entity_type

      t.timestamps
    end
    add_index :states, :name
    add_index :states, :recorded_at
    add_index :states, :stateful_entity_id
    add_index :states, :stateful_entity_type
  end

  def self.down
    drop_table :states
  end
end