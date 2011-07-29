# -*- encoding: utf-8 -*-
require 'lib/cash/version'

Gem::Specification.new do |s|
  s.name = %q{ngmoco-cache-money}
  s.version = Cash::VERSION

  s.required_rubygems_version = '1.3.7'
  s.authors = ["Nick Kallen", "Ashley Martens", "Scott Mace", "John O'Neill"]
  s.date = Date.today.to_s
  s.description = %q{Write-through and Read-through Cacheing for ActiveRecord}
  s.email = %q{teamplatform@ngmoco.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README",
    "README.markdown",
    "TODO"
  ]
  s.files = Dir[
    "README",
    "TODO",
    "UNSUPPORTED_FEATURES",
    "lib/**/*.rb",
    "rails/init.rb",
    "init.rb"
  ]
  s.homepage = %q{http://github.com/ngmoco/cache-money}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Write-through and Read-through Cacheing for ActiveRecord}
  s.test_files = Dir[
    "config/*",
    "db/schema.rb",
    "spec/**/*.rb"
  ]

  s.add_runtime_dependency(%q<activerecord>, [">= 2.2.0", "< 3.0"])
  s.add_runtime_dependency(%q<activesupport>, [">= 2.2.0", "< 3.0"])
  
  s.add_development_dependency(%q<rake>)
  s.add_development_dependency(%q<ruby-debug>, ["~> 0.10.0"])
  s.add_development_dependency(%q<rspec>, ["~> 1.3.0"])
  s.add_development_dependency(%q<sqlite3-ruby>)
  s.add_development_dependency(%q<rr>)
  s.add_development_dependency(%q<memcached>)
  s.add_development_dependency(%q<memcache-client>)
  s.add_development_dependency(%q<fakeredis>) 
end

