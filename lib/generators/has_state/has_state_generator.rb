require 'rails/generators'

class HasStateGenerator < Rails::Generators::Base
  
  desc "rails generate has_state:copy_files", "Copy has_state model and migration files to your app."
  def copy_files
    copy_file("app/models/state.rb", "app/models/state.rb")
    copy_file("db/migrate/create_states.rb", "db/migrate")
  end
end