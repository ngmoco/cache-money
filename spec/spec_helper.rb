dir = File.dirname(__FILE__)
$LOAD_PATH.unshift "#{dir}/../lib"

require 'rubygems'
require 'bundler'

require File.join(dir, '../config/environment')
require 'spec'
require 'pp'
require 'cache_money'

Spec::Runner.configure do |config|
  config.mock_with :rr
  config.before :suite do
    load File.join(dir, "../db/schema.rb")

    config = YAML.load(IO.read((File.expand_path(File.dirname(__FILE__) + "/../config/memcached.yml"))))['test']
    
    case ENV['ADAPTER']
    when 'memcache_client'
      # Test with MemCache client
      require 'cash/adapter/memcache_client'
      $memcache = Cash::Adapter::MemcacheClient.new(MemCache.new(config['servers']),
        :default_ttl => 1.minute.to_i)
      
    when 'redis'
      # Test with Redis client
      require 'cash/adapter/redis'
      require 'fakeredis'
      $memcache = Cash::Adapter::Redis.new(FakeRedis::Redis.new(),
        :default_ttl => 1.minute.to_i)
    when 'mock'
      # Test with Mock client
      require 'cash/adapter/memcache_client'
      require 'cash/mock'
      $memcache = Cash::Adapter::MemcacheClient.new(Cash::Mock.new(),
        :default_ttl => 1.minute.to_i)
    else
      require 'cash/adapter/memcached'
      # Test with memcached client
      $memcache = Cash::Adapter::Memcached.new(Memcached.new(config["servers"], config), 
        :default_ttl => 1.minute.to_i)
    end
  end

  config.before :each do
    $memcache.flush_all
    Story.delete_all
    Character.delete_all
  end

  config.before :suite do
    Cash.configure :repository => $memcache, :adapter => false
    
    ActiveRecord::Base.class_eval do
      is_cached
    end

    Character = Class.new(ActiveRecord::Base)
    Story = Class.new(ActiveRecord::Base)
    Story.has_many :characters

    Story.class_eval do
      index :title
      index [:id, :title]
      index :published
    end

    Short = Class.new(Story)
    Short.class_eval do
      index :subtitle, :order_column => 'title'
    end

    Epic = Class.new(Story)
    Oral = Class.new(Epic)

    Character.class_eval do
      index [:name, :story_id]
      index [:id, :story_id]
      index [:id, :name, :story_id]
    end

    Oral.class_eval do
      index :subtitle
    end
  end
end
