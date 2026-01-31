# frozen_string_literal: true

require "rails/railtie"

module Spectracer
  module Integrations
    class Railtie < Rails::Railtie
      rake_tasks do
        load "spectracer/tasks/spectracer.rake"
      end
    end
  end
end
