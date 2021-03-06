require 'cassandra'
require 'set'
require 'cassandra_object/attributes'
require 'cassandra_object/dirty'
require 'cassandra_object/persistence'

if CassandraObject.old_active_support
  require 'cassandra_object/legacy_callbacks'
else
  require 'cassandra_object/callbacks'
end

require 'cassandra_object/validation'
require 'cassandra_object/identity'
require 'cassandra_object/indexes'
require 'cassandra_object/serialization'
require 'cassandra_object/associations'
require 'cassandra_object/migrations'
require 'cassandra_object/cursor'
require 'cassandra_object/collection'
require 'cassandra_object/types'
require 'cassandra_object/mocking'
require 'cassandra_object/timestamps'

module CassandraObject
  class Base
    cattr_accessor :connection
    class_inheritable_writer :connection_class

    def self.connection_class
      read_inheritable_attribute(:connection_class) || Cassandra
    end

    module ConnectionManagement
      def establish_connection(*args)
        self.connection = connection_class.new(*args)
      end
    end
    extend ConnectionManagement

    module Naming
      def column_family=(column_family)
        write_inheritable_attribute(:column_family, column_family)
      end
      alias :set_column_family :column_family=

      def column_family
        read_inheritable_attribute(:column_family) || name.pluralize
      end

      def relationships_column_family=(name)
        write_inheritable_attribute(:relationships_column_family, name)
      end
      alias :set_relationships_column_family :relationships_column_family=

      def relationships_column_family
        read_inheritable_attribute(:relationships_column_family) || "#{column_family.singularize}Relationships"
      end
    end
    extend Naming

    if CassandraObject.old_active_support
      def self.lookup_ancestors
        super.select { |x| x.model_name.present? }
      end
    end

    extend ActiveModel::Naming

    module ConfigurationDumper
      def storage_config_xml
        subclasses.map(&:constantize).map(&:column_family_configuration).flatten.map do |config|
          config_to_xml(config)
        end.join("\n")
      end

      def config_to_xml(config)
        xml = "<ColumnFamily "
        config.each do |(attr_name, attr_value)|
          xml << " #{attr_name}=\"#{attr_value}\""
        end
        xml << " />"
        xml
      end
    end
    extend ConfigurationDumper
    
    include Callbacks
    include Identity
    include Attributes
    include Persistence
    include Indexes
    include Dirty

    include Timestamps
    include Validation
    include Associations

    attr_reader :attributes
    attr_accessor :key

    include Serialization
    include Migrations
    include Mocking

    def initialize(attributes={})
      @key = attributes.delete(:key)
      @new_record = true
      @attributes = {}.with_indifferent_access
      self.attributes = attributes
      @schema_version = self.class.current_schema_version
    end
  end
end

require 'cassandra_object/type_registration'
