class HasStateGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      # m.directory "lib"
      # m.template 'README', "README"
      m.file "app/models/state.rb","app/models/state.rb"
      m.file "app/controllers/state_controller.rb","app/controllers/state_controller.rb"
      m.migration_template "db/migrate/create_states.rb","db/migrate",:migration_file_name => "create_states"
    end
  end
end