module CassandraObject
  module Timestamps
    extend ActiveSupport::Concern

    module ClassMethods
      def timestamps!
        attribute :created_at, :type => :time
        attribute :updated_at, :type => :time
        before_create :on_create
        before_save   :on_save
      end
    end

    module InstanceMethods
      def on_create
        ts = Time.now
        self.created_at = ts
        self.updated_at = ts
      end

      def on_save
        self.updated_at = Time.now
      end
    end
  end
end