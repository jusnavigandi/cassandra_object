module CassandraObject
  module Timestamps
    extend ActiveSupport::Concern

    module ClassMethods
      def timestamps!
        attribute :created_at, :type => :time
        attribute :updated_at, :type => :time
      end
    end

    module InstanceMethods
      def save
        if has_timestamps?
          self.updated_at = Time.now
          self.created_at = self.updated_at if new_record?
        end
        super
      end

      protected
        def has_timestamps?
          methods.include?('updated_at') && methods.include?('created_at')
        end
    end
  end
end