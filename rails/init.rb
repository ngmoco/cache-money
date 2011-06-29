yml = YAML.load(IO.read(File.join(RAILS_ROOT, "config", "memcached.yml")))
memcache_config = yml[RAILS_ENV]

if memcache_config
  memcache_config.symbolize_keys! if memcache_config.respond_to?(:symbolize_keys!)

  memcache_config[:logger] = Rails.logger
  memcache_servers = 
    case memcache_config[:servers].class.to_s
      when "String"; memcache_config[:servers].gsub(' ', '').split(',')
      when "Array"; memcache_config[:servers]
    end
  Rails.logger.info '$memcache enabled.'
  $memcache = MemcachedWrapper.new(memcache_servers, memcache_config)
end
  

if defined?(DISABLE_CACHE_MONEY) || ENV['DISABLE_CACHE_MONEY'] == 'true' || memcache_config.nil? || memcache_config[:cache_money] != true
  Rails.logger.info 'cache-money disabled'
  class ActiveRecord::Base
    def self.index(*args)
    end
  end
else
  Rails.logger.info 'cache-money enabled'
  require 'cache_money'

  ActionController::Base.session_options[:cache] = $memcache if memcache_config[:sessions]
  $local = Cash::Local.new($memcache)
  $lock  = Cash::Lock.new($memcache)
  $cache = Cash::Transactional.new($local, $lock)

  # allow setting up caching on a per-model basis
  unless memcache_config[:automatic_caching].to_s == 'false'
    Rails.logger.info "cache-money: global model caching enabled"
    class ActiveRecord::Base
      is_cached(:repository => $cache)
    end
  end
end
