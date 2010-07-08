ActiveRecord::Schema.define(:version => 0) do
  create_table "states", :force => true do |t|
    t.string   "name"
    t.datetime "recorded_at"
    t.integer  "precedence"
    t.integer  "stateful_entity_id"
    t.string   "stateful_entity_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "states", ["name"], :name => "index_states_on_name"
  add_index "states", ["precedence"], :name => "index_states_on_precedence"
  add_index "states", ["recorded_at"], :name => "index_states_on_recorded_at"
  add_index "states", ["stateful_entity_id"], :name => "index_states_on_stateful_entity_id"
  add_index "states", ["stateful_entity_type"], :name => "index_states_on_stateful_entity_type"
end