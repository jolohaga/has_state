require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('has_state', '7.0.0') do |config|
  config.summary                  = 'Informal library implementing state machines.'
  config.author                   = 'Jose Hales-Garcia'
  config.url                      = 'http://github.com/jolohaga/has_state'
  config.email                    = 'jolohaga@me.com' 
  config.ignore_pattern           = ["tmp/*",".hg/*", ".pkg/*", ".git/*"]
  config.development_dependencies = ['rspec >=1.3.0','echoe >=4.3']
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each{|ext| load ext}