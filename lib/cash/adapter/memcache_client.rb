require 'memcache'

module Cash
  module Adapter
    class MemcacheClient
      def initialize(repository, options = {})
        @repository = repository
        @logger = options[:logger]
        @default_ttl = options[:default_ttl] || raise(":default_ttl is a required option")
      end

      def add(key, value, ttl=nil, raw=false)
        @repository.add(key, value, ttl || @default_ttl, raw)
      end
      
      def set(key, value, ttl=nil, raw=false)
        @repository.set(key, value, ttl || @default_ttl, raw)
      end
      
      def exception_classes
        MemCache::MemCacheError
      end
      
      def respond_to?(method)
        super || @repository.respond_to?(method)
      end
      
      private
      
        def method_missing(*args, &block)
          @repository.send(*args, &block)
        end
        
    end
  end
end
