# frozen_string_literal: true

require "tempfile"
require "zlib"

RSpec.describe Spectracer::IO::DependencyStore do
  subject(:store) { described_class.new }

  describe "#read" do
    context "when file does not exist" do
      it "returns empty hash" do
        expect(store.read("/nonexistent/file.json.gz")).to eq({})
      end
    end

    context "with gzipped JSON file" do
      let(:tempfile) { Tempfile.new(["test", ".json.gz"]) }
      let(:data) { {"spec/test_spec.rb" => ["app/test.rb"]} }

      before do
        Zlib::GzipWriter.open(tempfile.path) do |gz|
          gz.write(data.to_json)
        end
      end

      after { tempfile.unlink }

      it "reads and parses the file" do
        expect(store.read(tempfile.path)).to eq(data)
      end
    end

    context "with plain JSON file" do
      let(:tempfile) { Tempfile.new(["test", ".json"]) }
      let(:data) { {"key" => "value"} }

      before { File.write(tempfile.path, data.to_json) }
      after { tempfile.unlink }

      it "reads and parses the file" do
        expect(store.read(tempfile.path)).to eq(data)
      end
    end

    context "with invalid JSON" do
      let(:tempfile) { Tempfile.new(["test", ".json"]) }

      before { File.write(tempfile.path, "not valid json") }
      after { tempfile.unlink }

      it "returns empty hash" do
        expect(store.read(tempfile.path)).to eq({})
      end
    end
  end

  describe "#write" do
    let(:tempdir) { Dir.mktmpdir }
    let(:file_path) { File.join(tempdir, "nested", "dir", "output.json.gz") }
    let(:data) { {"spec/example_spec.rb" => ["app/example.rb"]} }

    after { FileUtils.rm_rf(tempdir) }

    it "creates nested directories" do
      store.write(data, file_path)
      expect(File.exist?(file_path)).to be true
    end

    it "writes valid gzipped JSON" do
      store.write(data, file_path)

      content = Zlib::GzipReader.open(file_path) { |gz| JSON.parse(gz.read) }
      expect(content).to eq(data)
    end
  end

  describe "#glob" do
    let(:tempdir) { Dir.mktmpdir }

    before do
      FileUtils.touch(File.join(tempdir, "file1.json.gz"))
      FileUtils.touch(File.join(tempdir, "file2.json.gz"))
      FileUtils.touch(File.join(tempdir, "other.txt"))
    end

    after { FileUtils.rm_rf(tempdir) }

    it "returns matching files" do
      files = store.glob(File.join(tempdir, "*.json.gz"))
      expect(files.length).to eq(2)
      expect(files).to all(end_with(".json.gz"))
    end
  end
end
