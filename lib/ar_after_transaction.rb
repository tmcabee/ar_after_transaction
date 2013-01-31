require 'active_record'
require 'ar_after_transaction/version'

module ARAfterTransaction
  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods

    base.class_eval do
      class << self
        alias_method_chain :transaction, :callback_support
      end
    end
  end

  module ClassMethods
    @@after_transaction_callbacks = {}

    def transaction_with_callback_support(*args, &block)
      clean = true
      transaction_without_callback_support(*args, &block)
    rescue Exception
      clean = false
      raise
    ensure
      unless transactions_open?
        callbacks = delete_after_transaction_callbacks
        callbacks.each(&:call) if clean
      end
    end

    def after_transaction &callback
      if transactions_open?
        add_after_transaction_callback callback
      else
        yield
      end
    end

    def normally_open_transactions
      @@normally_open_transactions ||= 0
    end

    def normally_open_transactions=(value)
      @@normally_open_transactions = value
    end

    private

    def database_name
      connection.instance_variable_get(:@config)[:database]
    end

    def transactions_open?
      connection.open_transactions > normally_open_transactions
    end

    def add_after_transaction_callback block
      @@after_transaction_callbacks[database_name] ||= []
      @@after_transaction_callbacks[database_name] << block
    end

    def delete_after_transaction_callbacks
      result = @@after_transaction_callbacks[database_name] || []
      @@after_transaction_callbacks[database_name] = []
      result
    end
  end

  module InstanceMethods
    def after_transaction(&block)
      self.class.after_transaction(&block)
    end
  end
end

ActiveRecord::Base.send(:include, ARAfterTransaction)