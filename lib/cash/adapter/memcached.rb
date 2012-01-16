require 'memcached'

# Maps memcached methods and semantics to those of memcache-client
module Cash
  module Adapter
    class Memcached
      def initialize(repository, options = {})
        @repository = repository
        @logger = options[:logger]
        @default_ttl = options[:default_ttl] || raise(":default_ttl is a required option")   
      end
      
      def add(key, value, ttl=nil, raw=false)
        wrap(key, not_stored) do
          logger.debug("Memcached add: #{key.inspect}") if debug_logger?
          @repository.add(key, raw ? value.to_s : value, ttl || @default_ttl, !raw)
          logger.debug("Memcached hit: #{key.inspect}") if debug_logger?
          stored
        end
      end
      
      # Wraps Memcached#get so that it doesn't raise. This has the side-effect of preventing you from 
      # storing <tt>nil</tt> values.
      def get(key, raw=false)
        wrap(key) do
          logger.debug("Memcached get: #{key.inspect}") if debug_logger?
          value = wrap(key) { @repository.get(key, !raw) }
          logger.debug("Memcached hit: #{key.inspect}") if debug_logger?
          value
        end
      end
      
      def get_multi(*keys)
        wrap(keys, {}) do
          begin
            keys.flatten!
            logger.debug("Memcached get_multi: #{keys.inspect}") if debug_logger?
            values = @repository.get(keys, true)
            logger.debug("Memcached hit: #{keys.inspect}") if debug_logger?
            values
          rescue TypeError
            log_error($!) if logger
            keys.each { |key| delete(key) }
            logger.debug("Memcached deleted: #{keys.inspect}") if debug_logger?
            {}
          end
        end
      end
      
      def set(key, value, ttl=nil, raw=false)
        wrap(key, not_stored) do
          logger.debug("Memcached set: #{key.inspect}") if debug_logger?
          @repository.set(key, raw ? value.to_s : value, ttl || @default_ttl, !raw)
          logger.debug("Memcached hit: #{key.inspect}") if debug_logger?
          stored
        end
      end
      
      def delete(key)
        wrap(key, not_found) do
          logger.debug("Memcached delete: #{key.inspect}") if debug_logger?
          @repository.delete(key)
          logger.debug("Memcached hit: #{key.inspect}") if debug_logger?
          deleted
        end
      end
      
      def get_server_for_key(key)
        wrap(key) { @repository.server_by_key(key) }
      end

      def incr(key, value = 1)
        wrap(key) { @repository.incr(key, value) }
      end

      def decr(key, value = 1)
        wrap(key) { @repository.decr(key, value) }
      end
      
      def flush_all
        @repository.flush
      end
      
      def exception_classes
        ::Memcached::Error
      end
      
      private
      
        def logger
          @logger
        end
        
        def debug_logger?
          logger && logger.respond_to?(:debug?) && logger.debug?
        end
        
        def wrap(key, error_value = nil, options = {})
          yield
        rescue ::Memcached::NotStored
          logger.debug("Memcached miss: #{key.inspect}") if debug_logger?
          error_value
        rescue ::Memcached::Error
          log_error($!) if logger
          raise if options[:reraise_error]
          error_value
        end
        
        def stored
          "STORED\r\n"
        end

        def deleted
          "DELETED\r\n"
        end

        def not_stored
          "NOT_STORED\r\n"
        end

        def not_found
          "NOT_FOUND\r\n"
        end

        def log_error(err)
          #logger.error("#{err}: \n\t#{err.backtrace.join("\n\t")}") if logger
          logger.error("Memcached ERROR, #{err.class}: #{err}") if logger
        end
    end
  end
end
