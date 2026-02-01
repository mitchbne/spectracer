# frozen_string_literal: true

RSpec.describe Spectracer::Core::PathFilter do
  describe "#gem_path?" do
    subject(:path_filter) { described_class.new(gem_paths: gem_paths, bundler_path: bundler_path) }

    let(:gem_paths) { ["/usr/local/lib/ruby/gems/3.2.0", "/home/user/.gem/ruby/3.2.0"] }
    let(:bundler_path) { "/app/vendor/bundle" }

    it "returns true for paths inside gem directories" do
      expect(path_filter.gem_path?("/usr/local/lib/ruby/gems/3.2.0/gems/rspec-3.12.0/lib/rspec.rb")).to be true
    end

    it "returns true for paths inside user gem directory" do
      expect(path_filter.gem_path?("/home/user/.gem/ruby/3.2.0/gems/rails-7.0.0/lib/rails.rb")).to be true
    end

    it "returns true for paths inside bundler directory" do
      expect(path_filter.gem_path?("/app/vendor/bundle/ruby/3.2.0/gems/puma-6.0.0/lib/puma.rb")).to be true
    end

    it "returns false for application paths" do
      expect(path_filter.gem_path?("/app/lib/my_class.rb")).to be false
    end

    it "returns false for paths that contain gem path as substring but don't start with it" do
      expect(path_filter.gem_path?("/some/other/usr/local/lib/ruby/gems/3.2.0/file.rb")).to be false
    end

    context "when bundler_path is nil" do
      let(:bundler_path) { nil }

      it "still filters gem paths" do
        expect(path_filter.gem_path?("/usr/local/lib/ruby/gems/3.2.0/gems/rspec-3.12.0/lib/rspec.rb")).to be true
      end

      it "does not error on application paths" do
        expect(path_filter.gem_path?("/app/lib/my_class.rb")).to be false
      end
    end
  end

  describe "#app_path?" do
    subject(:path_filter) { described_class.new(gem_paths: ["/gems"], bundler_path: nil) }

    it "returns true for non-gem paths" do
      expect(path_filter.app_path?("/app/lib/my_class.rb")).to be true
    end

    it "returns false for gem paths" do
      expect(path_filter.app_path?("/gems/rspec/lib/rspec.rb")).to be false
    end
  end
end
