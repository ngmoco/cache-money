require 'rubygems'
require 'bundler/setup'
Bundler.require :default, 'development'
require File.expand_path('../config/environment', __FILE__)

begin
  require 'rake/testtask'
  require 'rake/rdoctask'
  require 'spec/rake/spectask'
rescue MissingSourceFile
  STDERR.puts "Error, could not load rake/rspec tasks! (#{$!})\n\nDid you run `bundle install`?\n\n"
  exit 1
end

require 'lib/cash/version'

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--format', 'profile', '--color']
end

Spec::Rake::SpecTask.new(:coverage) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = ['-x', 'spec,gems']
end

desc "Default task is to run specs"
task :default => :spec

namespace :britt do
  desc 'Removes trailing whitespace'
  task :space do
    sh %{find . -name '*.rb' -exec sed -i '' 's/ *$//g' {} \\;}
  end
end


desc "Push a new version to Gemcutter"
task :publish => [ :spec, :build ] do
  system "git tag v#{Cash::VERSION}"
  system "git push origin v#{Cash::VERSION}"
  system "git push origin master"
  system "gem push pkg/eliasbaixas-cache-money-#{Cash::VERSION}.gem"
  system "git clean -fd"
end
