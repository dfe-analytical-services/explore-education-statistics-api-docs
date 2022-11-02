module ApiReferenceHelpers
  # @param [Openapi3Parser::Node::Schema] schema_data
  # @return [*]
  def schema_example(schema_data)
    if schema_data.example
      return schema_data.example
    end

    if Utils::is_primitive_schema(schema_data)
      return Utils::primitive_schema_example(schema_data)
    end

    if schema_data.type == "array"
      items = schema_data.items
      return items ? [schema_example(items)] : []
    end

    # TODO - Implement other complex schemas anyOf, oneOf, not, etc

    properties = schema_data.properties.to_h

    schema_data.all_of.to_a.each do |all_of_schema|
      properties.merge!(all_of_schema.properties.to_h)
    end

    properties = properties.each_with_object({}) do |(name, schema), memo|
      memo[name] = case schema.type
                   when "object"
                     schema_example(schema)
                   when "array"
                     schema.items && schema.items != schema_data ? [schema_example(schema.items)] : []
                   else
                     Utils::primitive_schema_example(schema)
                   end
    end

    if schema_data.additional_properties?
      properties["<*>"] = schema_example(schema_data.additional_properties_schema)
    end

    properties
  end

  # @param [Openapi3Parser::Node::Schema] schema
  # @return [String]
  def render_schema_type(schema)
    if schema.type == "object"
      unless schema.name
        if schema.additional_properties?
          return "dictionary (#{render_schema_type(schema.additional_properties_schema)})"
        end

        return "object"
      end

      href = ::Middleman::Util::url_for(@app, "/schemas/#{schema.name}/index.html", {
        current_resource: current_resource
      })

      "<a href='#{href}'>#{schema.name}</a>"
    elsif schema.type == "array"
      items = schema.items

      if items.nil?
        return "array"
      end

      if items.type == "object" && items.name
        href = ::Middleman::Util::url_for(@app, "/schemas/#{items.name}/index.html", {
          current_resource: current_resource
        })

        "array (<a href='#{href}'>#{items.name}</a>)"
      else
        "array (#{render_schema_type(items)})"
      end
    else
      schema.type || ""
    end
  end

  class Utils
    # @param [Openapi3Parser::Node::Schema] schema
    # @return [String, Number, Boolean]
    def self.primitive_schema_example(schema)
      case schema.type
      when "string"
        schema.format ? "string(#{schema.format})" : "string"
      when "number", "integer"
        0
      when "boolean"
        true
      else
        raise "Invalid primitive schema type: #{schema.type}"
      end
    end

    # @param [Openapi3Parser::Node::Schema] schema
    # @return [Boolean]
    def self.is_complex_schema(schema)
      !!(schema.all_of || schema.any_of || schema.one_of || schema.not)
    end

    # @param [Openapi3Parser::Node::Schema] schema
    # @return [Boolean]
    def self.is_primitive_schema(schema)
      !is_complex_schema(schema) && !schema.type.nil? && schema.type != "object" && schema.type != "array"
    end
  end
end
