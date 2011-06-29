require 'active_support'
require 'active_record'

require 'cash/lock'
require 'cash/transactional'
require 'cash/write_through'
require 'cash/finders'
require 'cash/buffered'
require 'cash/index'
require 'cash/config'
require 'cash/accessor'

require 'cash/request'
require 'cash/fake'
require 'cash/local'

require 'cash/query/abstract'
require 'cash/query/select'
require 'cash/query/primary_key'
require 'cash/query/calculation'

require 'cash/util/array'
require 'cash/util/marshal'

class ActiveRecord::Base
  def self.is_cached(options = {})
    if (options == false || options[:repository].nil?)
      include NoCash
    else
      options.assert_valid_keys(:ttl, :repository, :version)
      include Cash unless ancestors.include?(Cash)
      Cash::Config.create(self, options)
    end
  end

  def <=>(other)
    if self.id == other.id then 
      0
    else
      self.id < other.id ? -1 : 1
    end
  end
end

module Cash
  def self.included(active_record_class)
    active_record_class.class_eval do
      include Config, Accessor, WriteThrough, Finders
      extend ClassMethods
    end
  end

  module ClassMethods
    def self.extended(active_record_class)
      class << active_record_class
        alias_method_chain :transaction, :cache_transaction
      end
    end

    def transaction_with_cache_transaction(*args)
      if cache_config
        # Wrap both the db and cache transaction in another cache transaction so that the cache 
        # gets written only after the database commit but can still flush the inner cache
        # transaction if an AR::Rollback is issued.
        repository.transaction do
          transaction_without_cache_transaction(*args) do
            repository.transaction { yield }
          end
        end
      else
        transaction_without_cache_transaction(*args)
      end
    end

    def cacheable?(*args)
      true
    end
  end
end
module NoCash
  def self.included(active_record_class)
    active_record_class.class_eval do
      extend ClassMethods
    end
  end
  module ClassMethods
    def cacheable?(*args)
      false
    end
  end
end