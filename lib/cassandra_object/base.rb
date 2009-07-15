require 'cassandra_client'
require 'set'

module CassandraObject
  class Base
    
    superclass_delegating_accessor :connection
    module ConnectionManagement
      def establish_connection(*args)
        self.connection = CassandraClient.new(*args)
      end
    end
    extend ConnectionManagement
    
    module Naming
      def column_family
        name.pluralize
      end
    end
    extend Naming
    
    class Attribute
      attr_reader :name
      def initialize(name, options)
        @name = name.to_s
        @options = options
      end
      
      def check_value!(value)
        return value if value.nil? || value.is_a?(expected_type)
        
        if expected_type == Date
          value = Date.strptime(value, "%Y-%m-%d") 
        end
        unless value.is_a?(expected_type)
          raise TypeError, "#{@name} must be a #{expected_type.inspect} but you gave #{value.inspect}"
        end
      end
      
      def expected_type
        @options[:type] || String
      end
    end
    
    superclass_delegating_accessor :attributes
    module Attributes
      def attribute(name, options)
        (self.attributes ||= ActiveSupport::OrderedHash.new)[name.to_s] = Attribute.new(name, options)
      end
    end
    extend Attributes
    
    module Fetching
      def get(id)
        attr_names = attributes.values.map(&:name)
        attr_values = connection.get_columns(column_family, id, attr_names)
        new(id, Hash[*attr_names.zip(attr_values).flatten])
      end

      def create(attributes)
        new(nil, attributes).save
      end

      def write(id, attributes)
        unless id
          id = next_id
        end
        connection.insert(column_family, id, attributes.stringify_keys)
        return id
      end
    end
    extend Fetching
    
    
    def self.next_id
      [Time.now.utc.strftime("%Y%m%d%H%M%S"), Process.pid, rand(1024)] * ""
    end
    
    attr_reader :id, :attributes
    
    def initialize(id, attributes)
      @id = id
      @changed_attribute_names = Set.new
      @attributes = {}.with_indifferent_access
      self.attributes=attributes
      @changed_attribute_names = Set.new
    end
    
    def method_missing(name, *args)
      name = name.to_s
      if name =~ /^(.*)=$/
        write_attribute($1, args.first)
      elsif @attributes.include?(name)
        read_attribute(name)
      else
        super
      end
    end
    
    def write_attribute(name, value)
      value = self.class.attributes[name].check_value!(value)
      @changed_attribute_names << name
      @attributes[name] = value
    end
    
    def read_attribute(name)
      @attributes[name]
    end
    
    def changed_attributes
      if new_record?
        @attributes
      else
        @changed_attribute_names.inject({}) do |memo, name|
          memo[name] = read_attribute(name)
          memo
        end
      end
    end
    
    def attributes=(attributes)
      attributes.each do |(name, value)|
        send("#{name}=", value)
      end
    end
        
    
    def new_record?
      @id.nil?
    end
    
    def save
      @id = self.class.write(id, changed_attributes)
      self
    end
  end
end