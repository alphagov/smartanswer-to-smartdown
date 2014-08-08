# encoding: utf-8
require 'pathname'
require 'tmpdir'
require 'fileutils'

describe "smartanswer-to-smartdown" do
  def app_root
    Pathname.new("../..").expand_path(File.dirname(__FILE__))
  end

  def path(relative_path)
    app_root + relative_path
  end

  before(:each) do
    FileUtils.mkdir(path('tmp')) unless File.directory?(path('tmp'))
    @tmpdir = Dir.mktmpdir("test-output-", path('tmp'))
  end

  after(:each) do
    FileUtils.remove_entry_secure(@tmpdir)
  end

  RSpec::Matchers.define :be_an_identical_directory_tree_to do |expected_directory_tree_path|
    match do |actual_directory_tree_path|
      @comparison_output = `diff -u -r #{expected_directory_tree_path} #{actual_directory_tree_path}`.force_encoding("utf-8")
      $?.success?
    end

    failure_message do |actual_directory_tree_path|
      "expected that '#{actual_directory_tree_path}' would be a an identical " +
      "directory tree to '#{expected_directory_tree_path}' but there were " +
      "differences:\n\n" +
      @comparison_output.gsub(/^/, "  ")
    end

  end

  let(:sample_dir) { path('spec/fixtures/acceptance') }

  before(:each) do
    Bundler.with_clean_env do
      output = `bundle exec #{path('bin')}/smartanswer-to-smartdown #{sample_dir + flow_name + 'input/lib/flows' + "#{flow_name}.rb"} #{@tmpdir} 2>&1`
      raise(output) unless $?.success?
      if !output.strip.empty?
        puts output
      end
    end
  end

  context "check uk visa" do
    let(:flow_name) { "check-uk-visa" }

    it "reads a smartanswer, parses it and spits out files" do
      expect(@tmpdir).to be_an_identical_directory_tree_to(sample_dir + flow_name + 'expected_output')
    end
  end

  xcontext "marriage abroad" do
    let(:flow_name) { "marriage-abroad" }

    it "reads a smartanswer, parses it and spits out files" do
      expect(@tmpdir).to be_an_identical_directory_tree_to(sample_dir + flow_name + 'expected_output')
    end
  end
end
