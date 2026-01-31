# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

# Load spectracer rake tasks
require_relative "lib/spectracer"
load "lib/spectracer/tasks/spectracer.rake"

task default: %i[spec standard]
