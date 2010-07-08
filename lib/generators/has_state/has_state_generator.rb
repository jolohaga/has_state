require 'rails/generators'
require 'rails/generators/migration'

class HasStateGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  
  source_root File.expand_path('../templates',__FILE__)
  
  def generate_model
    copy_file 'app/models/state.rb', 'app/models/state.rb'
  end
  
  def generate_migration
    migration_template 'db/migrate/create_states.rb', 'db/migrate/create_states.rb'
  end
  
  def self.next_migration_number(dirname)
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end
end