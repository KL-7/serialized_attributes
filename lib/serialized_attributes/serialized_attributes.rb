module SerializedAttributes

  def self.included(base)
    return if base.respond_to?(:serialized_attributes_definition)

    base.class_eval do
      class_inheritable_hash :serialized_attributes_definition
      write_inheritable_attribute(:serialized_attributes_definition, {})

      cattr_accessor :serialized_attributes_column
      self.serialized_attributes_column = :serialized_attributes
      serialize serialized_attributes_column, Hash

      base.extend ClassMethods
    end
  end

  module ClassMethods

    def instantiate(record)
      object = super(record)
      object.unpack_serialized_attributes!
      object
    end

    def accessible_attribute(name, type, opts = {})
      attribute(name, type, opts.merge(:attr_accessible => true))
    end

    def serialized_attribute_names
      serialized_attributes_definition.keys
    end

    def attribute(name, type, opts = {})
      name = name.to_s
      type = SerializedAttributes.type_to_sqltype(type)
      serialized_attributes_definition[name] = ActiveRecord::ConnectionAdapters::Column.new(name.to_s, opts[:default], type.to_s, nil)

      define_method("#{name.to_s}=".to_sym) { |value| @attributes[name] = value }
      define_method(name) { self.class.serialized_attributes_definition[name].type_cast(@attributes.fetch(name, opts[:default])) }
      alias_method("#{name}?", name) if type == :boolean

      attr_accessible name if opts[:attr_accessible]
    end

  end

  def create_or_update
    pack_serialized_attributes!
    super
  end

  def serialized_attribute_names
    self.class.serialized_attribute_names
  end

  def unpack_serialized_attributes!
    if @attributes.has_key?(serialized_attributes_column.to_s)
      attributes = self[serialized_attributes_column] || {}

      serialized_attributes_definition.each do |key, column|
        @attributes[key] = attributes.has_key?(key) ? attributes[key] : column.default
      end

      attributes.slice!(*serialized_attribute_names)
    end
  end

  def pack_serialized_attributes!
    if @attributes.has_key?(serialized_attributes_column.to_s)
      attributes = self[serialized_attributes_column] ||= {}

      serialized_attributes_definition.each_key do |key|
        attributes[key] = send(key)
      end
    end

    attributes.slice!(*serialized_attribute_names)
  end

  Boolean = Class.new # stub for Boolean type

  class << self

    CLASSES_TO_SQL_TYPES = {
        String     => :string,
        Boolean    => :boolean,
        Fixnum     => :integer,
        Integer    => :integer,
        BigDecimal => :decimal,
        Float      => :float,
        Date       => :date,
        Time       => :time,
        DateTime   => :time
    }

    def type_to_sqltype(type)
      CLASSES_TO_SQL_TYPES.fetch(type, type)
    end

  end

end
