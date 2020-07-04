annotation Memoize
end

class Object
  macro method_added(method)
    {% if method.annotation(Memoize) %}
      memoize method
    {% end %}
  end
end

module MailHelpers
  def mail(email : Carbon::Email.class, *args, **kwargs) : Nil
    email.new(*args, **kwargs).deliver
  end

  def mail_later(email : Carbon::Email.class, *args, **kwargs) : Nil
    email.new(*args, **kwargs).deliver_later
  end
end

class String
  # Source: https://github.com/amberframework/amber/blob/master/src/amber/extensions/string.cr
  def email? : Bool
    !!match(/^[_]*([a-z0-9]+(\.|_*)?)+@([a-z][a-z0-9-]+(\.|-*\.))+[a-z]{2,6}$/)
  end
end

module Lucky
  module MountComponent
    def mount(component : Lucky::BaseComponent.class, *args, **kwargs) : Nil
      mount component.new(*args, **kwargs)
    end

    def mount(component : Lucky::BaseComponent.class, *args, **kwargs) : Nil
      mount component.new(*args, **kwargs) do |*yield_args|
        yield *yield_args
      end
    end
  end

  abstract class Action
    include MailHelpers
  end
end

module Avram
  class Operation
    include MailHelpers
  end

  abstract class SaveOperation(T)
    def record!
      record.not_nil!
    end
  end

  # Avram's implementation errors in an update operation:
  #
  # `duplicate key value violates unique constraint
  # "<constraint name>" (PQ::PQError)`
  #
  # `{{ type }}.new(params)` causes `{{ name }}.save` to create
  # (rather than update) a record each time it is called, since
  # no record was passed when the nested operation was instantiated.
  #
  # Ref: https://github.com/luckyframework/avram/blob/master/src/avram/nested_save_operation.cr
  module NestedSaveOperation
    NESTED_SAVE_OPERATIONS = [] of Avram::MarkAsFailed

    macro has_one(type_declaration, *, assoc_name)
      {% name = type_declaration.var %}
      {% type = type_declaration.type %}

      {% nested_attributes = type.resolve.constant(:ATTRIBUTES) %}
      {% nested_columns =
        type.resolve.constant(:COLUMN_ATTRIBUTES).reject do |c|
          c[:autogenerated] || c[:name].id == @type.constant(:FOREIGN_KEY).id
        end
      %}

      {% for nested_attribute in nested_attributes %}
        attribute {{ nested_attribute }}
      {% end %}

      {% for nested_column in nested_columns %}
        attribute {{ nested_column[:name].id }} : {{ nested_column[:type].id }}
      {% end %}

      before_save update_nested_{{ name }}
      after_save create_nested_{{ name }}

      def update_nested_{{ name }}
        return if new_record?

        nested = {{ type }}.new(
          record!.{{ assoc_name.id }}!,
          params,
          {% for nested_attribute in nested_attributes %}
            {{ nested_attribute.var }}: {{ nested_attribute.var }}.value.nil? ?
              Nothing.new :
              {{ nested_attribute.var }}.value.not_nil!,
          {% end %}
          {% for nested_column in nested_columns %}
            {{ nested_column[:name].id }}: {{ nested_column[:name].id }}.value.nil? ?
              Nothing.new :
              {{ nested_column[:name].id }}.value.not_nil!,
          {% end %}
        )

        NESTED_SAVE_OPERATIONS << nested

        unless nested.save
          {% for nested_attribute in nested_attributes %}
            nested.{{ nested_attribute.var }}.errors.each do |error|
              {{ nested_attribute.var }}.add_error(error)
            end
          {% end %}

          {% for nested_column in nested_columns %}
            nested.{{ nested_column[:name].id }}.errors.each do |error|
              {{ nested_column[:name].id }}.add_error(error)
            end
          {% end %}
        end
      end

      def create_nested_{{ name }}(record)
        return unless new_record?

        nested = {{ type }}.new(
          params,
          {% for nested_attribute in nested_attributes %}
            {{ nested_attribute.var }}: {{ nested_attribute.var }}.value.nil? ?
              Nothing.new :
              {{ nested_attribute.var }}.value.not_nil!,
          {% end %}
          {% for nested_column in nested_columns %}
            {{ nested_column[:name].id }}: {{ nested_column[:name].id }}.value.nil? ?
              Nothing.new :
              {{ nested_column[:name].id }}.value.not_nil!,
          {% end %}
        )

        nested.{{ @type.constant(:FOREIGN_KEY).id }}.value = record.id

        NESTED_SAVE_OPERATIONS << nested

        unless nested.save
          NESTED_SAVE_OPERATIONS.each &.mark_as_failed
          database.rollback
        end
      end
    end
  end

  module NeedyInitializerAndSaveMethods
    # Monkey patching to add `#new_record?`
    #
    # `#persisted?` returns `true`, always, in `after_save` (and
    # `after_commit`), so it is not a viable method for checking
    # whether or not we did a create (vs. update) operation.
    #
    # Ref: https://github.com/luckyframework/avram/blob/3fe881faee2da2bc63ae0fed49ecccca1876b0dc/src/avram/needy_initializer_and_save_methods.cr#L162
    macro generate_initializer(attribute_method_args, attribute_params)
      {% needs_method_args = "" %}
      {% for type_declaration in OPERATION_NEEDS %}
        {% needs_method_args = needs_method_args + "@#{type_declaration},\n" %}
      {% end %}

      getter? new_record : Bool

      def initialize(
          @record : T,
          @params : Avram::Paramable,
          {{ needs_method_args.id }}
          {{ attribute_method_args.id }}
        )

        @new_record = false
        set_attributes({{ attribute_params.id }})
      end

      def initialize(
          @params : Avram::Paramable,
          {{ needs_method_args.id }}
          {{ attribute_method_args.id }}
      )
        @record = nil
        @new_record = true
        set_attributes({{ attribute_params.id }})
      end

      def initialize(
          @record : T,
          {{ needs_method_args.id }}
          {{ attribute_method_args.id }}
      )
        @params = Avram::Params.new
        @new_record = false
        set_attributes({{ attribute_params.id }})
      end

      def initialize(
          {{ needs_method_args.id }}
          {{ attribute_method_args.id }}
      )
        @record = nil
        @params = Avram::Params.new
        @new_record = true
        set_attributes({{ attribute_params.id }})
      end

      def set_attributes({{ attribute_method_args.id }})
        {% if @type.constant :COLUMN_ATTRIBUTES %}
          {% for attribute in COLUMN_ATTRIBUTES.uniq %}
            unless {{ attribute[:name] }}.is_a? Nothing
              self.{{ attribute[:name] }}.value = {{ attribute[:name] }}
            end
          {% end %}
        {% end %}

        {% for attribute in ATTRIBUTES %}
          unless {{ attribute.var }}.is_a? Nothing
            self.{{ attribute.var }}.value = {{ attribute.var }}
          end
        {% end %}
        extract_changes_from_params
      end
    end
  end
end

struct Socket::IPAddress
  def self.adapter
    Lucky
  end

  def ip4? : Bool
    ip4? address
  end

  def ip6? : Bool
    ip6? address
  end

  module Lucky
    alias ColumnType = String

    include Avram::Type

    def from_db!(value : String)
      port = value.match /[^:\]]*$/
      address = value.rchop port.to_s

      IPAddress.new(address, port.try(&.[0].to_i) || 0)
    end

    def parse(value : IPAddress)
      SuccessfulCast(IPAddress).new(value)
    end

    def parse(value : String)
      SuccessfulCast(IPAddress).new(IPAddress.parse(value))
    rescue
      FailedCast.new
    end

    def to_db(value : String)
      value
    end

    def to_db(value : IPAddress)
      value.to_s
    end

    class Criteria(T, V) < String::Lucky::Criteria(T, V)
    end
  end
end
