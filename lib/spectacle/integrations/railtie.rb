# frozen_string_literal: true

require "rails/railtie"

module Spectacle
  module Integrations
    class Railtie < Rails::Railtie
      rake_tasks do
        load "spectacle/tasks/spectacle.rake"
      end
    end
  end
end
