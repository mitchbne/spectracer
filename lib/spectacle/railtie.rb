require 'rails/railtie'

module Spectacle
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/spectacle.rake'
    end
  end
end
