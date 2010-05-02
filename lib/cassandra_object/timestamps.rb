module CassandraObject
  module Timestamps
    extend ActiveSupport::Concern

    module ClassMethods
      def timestamps!
        attribute :created_at, :type => :time
        attribute :updated_at, :type => :time

        before_save do |record|
          record.updated_at = Time.now
          record.created_at = record.updated_at if record.new_record?
        end
      end
    end
  end
end