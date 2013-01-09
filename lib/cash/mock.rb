module Cash
  class Mock < HashWithIndifferentAccess
    attr_accessor :servers

    class CacheEntry
      attr_reader :value
      
      def self.default_ttl
        1_000_000
      end

      def self.now
        Time.now
      end
      
      def initialize(value, raw, ttl)
        if raw
          @value = value.to_s
        else
          @value = Marshal.dump(value)
        end
        
        if ttl.nil? || ttl.zero?
          @ttl = self.class.default_ttl
        else
          @ttl = ttl
        end
        
        @expires_at = self.class.now + @ttl
      end
      
      
      def expired?
        self.class.now > @expires_at
      end
      
      def increment(amount = 1)
        @value = (@value.to_i + amount).to_s
      end
      
      def decrement(amount = 1)
        @value = (@value.to_i - amount).to_s
      end
      
      def unmarshal
        Marshal.load(@value)
      end
      
      def to_i
        @value.to_i
      end
    end
    
    attr_accessor :logging
    
    def initialize
      @logging = false
    end
    
    def get_multi(*keys)
      slice(*keys).collect { |k,v| [k, v.unmarshal] }.to_hash_without_nils
    end

    def set(key, value, ttl = CacheEntry.default_ttl, raw = false)
      log "< set #{key} #{ttl}"
      self[key] = CacheEntry.new(value, raw, ttl)
      log('> STORED')
    end

    def get(key, raw = false)
      if key.is_a?(Array)
        get_multi(*key)
      else
        log "< get #{key}"
        unless self.has_unexpired_key?(key)
          log('> END')
          return nil
        end
        
        log("> sending key #{key}")
        log('> END')
        if raw
          self[key].value
        else
          self[key].unmarshal
        end
      end
    end
    
    def delete(key, options = {})
      log "< delete #{key}"
      if self.has_unexpired_key?(key)
        log "> DELETED"
        super(key)
      else
        log "> NOT FOUND"
      end
    end

    def incr(key, amount = 1)
      if self.has_unexpired_key?(key)
        self[key].increment(amount)
        self[key].to_i
      end
    end

    def decr(key, amount = 1)
      if self.has_unexpired_key?(key)
        self[key].decrement(amount)
        self[key].to_i
      end
    end

    def add(key, value, ttl = CacheEntry.default_ttl, raw = false)
      if self.has_unexpired_key?(key)
        "NOT_STORED\r\n"
      else
        set(key, value, ttl, raw)
        "STORED\r\n"
      end
    end

    def append(key, value)
      set(key, get(key, true).to_s + value.to_s, nil, true)
    end

    def namespace
      nil
    end

    def flush_all
      log('< flush_all')
      clear
    end

    def stats
      {}
    end

    def reset_runtime
      [0, Hash.new(0)]
    end

    def has_unexpired_key?(key)
      self.has_key?(key) && !self[key].expired?
    end
    
    def log(message)
      return unless logging
      logger.debug(message)
    end
    
    def logger
      @logger ||= ActiveSupport::BufferedLogger.new(Rails.root.join('log/cash_mock.log'))
    end
    
  end
end
