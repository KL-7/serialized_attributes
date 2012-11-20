require 'test/unit'
require 'rubygems'
require 'active_record'
require 'logger'

require "./lib/serialized_attributes"

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

class DocumentsSchema < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.text :serialized_attributes_data
      t.string :type
      t.timestamps
    end

    create_table :widgets do |t|
      t.string :name
      t.boolean :active
      t.text :serialized_attributes_data
      t.timestamps
    end
  end
end

class Document < ActiveRecord::Base
  # base class without serialized attributes support
end

class Post < Document
  include SerializedAttributes

  attribute :title, String
  attribute :body,  String
  attribute :is_published, Boolean, :default => false

  validates_presence_of :title, :body
end

class Comment < Document
  include SerializedAttributes

  attribute :body, String
  attribute :post_id, Integer
  belongs_to :post

  validates_presence_of :body
end

class CommentWithAuthor < Comment
  attribute :author, String
end

class ModelBefore < ActiveRecord::Base
  self.table_name = :documents
end

class ModelAfter < ActiveRecord::Base
  self.table_name = :documents
  include SerializedAttributes
  attribute :custom_field, String, :default => 'default value'
end

class ModelSecond < ActiveRecord::Base
  self.table_name = :documents
  include SerializedAttributes
  attribute :custom_field_renamed, String, :default => 'new default value'
end

class Widget < ActiveRecord::Base
  include SerializedAttributes

  # white list the name attribute, others may not be mass assigned
  attr_accessible :name, String
end

class Sprocket < Widget
  # we want the attribute in_motion, but it may not be mass assigned
  attribute :in_motion, Boolean

  # we want to allow the size attribute to be mass assigned
  accessible_attribute :size, Integer
end


class SimpleTest < Test::Unit::TestCase
  DocumentsSchema.suppress_messages { DocumentsSchema.migrate(:up) }

  # => test that nothing fails if the a parent class doesn't have serialized attributes
  def test_parent_class_without_serialized_attributes
    assert_equal false, Document.respond_to?(:serialized_attributes_definition)
    assert_equal true, Comment.respond_to?(:serialized_attributes_definition)
  end

  # => test that serialized attribute definitions are not propagated back to the parent class
  def test_child_attributes_are_not_added_to_the_parent_model
    assert_equal %w[author body post_id], CommentWithAuthor.serialized_attribute_names.sort
    assert_equal %w[body post_id], Comment.serialized_attribute_names.sort
  end

  # => it should initialize attributes on objects even if they were serialized before that attribute existed
  def test_null_serialized_attributes_column_on_already_exists_records
    # => to test this, we create a model (ModelBefore) that has no attributes (but has an attributes column)
    # => then we create second model (ModelAfter) which we force to use the same table as ModelBefore (set_table_name)
    # => We create an object using ModelBefore and then try to load it using ModelAfter.
    model_before = ModelBefore.create
    model_after = ModelAfter.find(model_before.id)

    assert_equal 'default value', model_after.custom_field
  end

  # => it should not unpack custom attributes on objects if they have been removed
  def test_removed_custom_field
    # => to test this, we use a similar method to the prior test, but change (or remove) an attribute
    model1 = ModelAfter.create
    model2 = ModelSecond.find(model1.id)
    model2.save!
    model2.reload

    assert_equal false, model2.serialized_attributes_data.include?('custom_field')
  end

  # => it should create attributes as whitelisted and allow their mass assignment
  def test_accessible_attributes_are_created
    sprocket = Sprocket.create(:name => "Spacely's Space Sprocket", :size => 99)
    assert_equal 99, sprocket.size
  end

  # => test that the names of the serialized attributes are correctly returned by a class
  def test_serizalied_attribute_names_are_returned_by_the_class
    assert_equal %w[in_motion size], Sprocket.serialized_attribute_names.sort
  end

  # => test that the names of the serialized attributes are correctly returned by the instance
  def test_serizalied_attribute_names_are_returned_by_an_instance
    assert_equal %w[in_motion size], Sprocket.new.serialized_attribute_names.sort
  end

  # => test that default value is properly used in just created model
  def test_default_value_in_just_create_model
    assert_equal 'new default value', ModelSecond.new.custom_field_renamed
  end

  # => test that default value is properly used in saved model
  def test_default_value_in_save_model
    model = ModelSecond.create
    model.reload

    assert_equal 'new default value', model.custom_field_renamed
  end

  # => test that attribute_name? methods are defined for boolean attributes
  def test_boolean_attribute_getter_with_a_question_mark
    widget = Sprocket.new

    widget.in_motion = true
    assert_equal true, widget.in_motion?

    widget.in_motion = false
    assert_equal false, widget.in_motion?
  end
end
