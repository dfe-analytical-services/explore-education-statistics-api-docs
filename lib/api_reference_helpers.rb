module ApiReferenceHelpers
  # @param [Openapi3Parser::Node::Schema] schema_data
  # @param [Array<Openapi3Parser::Node::Schema>] references
  # @return [*]
  def schema_example(schema_data, references = [])
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

    if schema_data.one_of&.any?
      return schema_example(schema_data.one_of[0])
    end

    # TODO - Implement other complex schemas anyOf, not, etc

    properties = get_schema_properties(schema_data)

    properties = properties.each_with_object({}) do |(name, schema), memo|
      memo[name] = case schema.type
                   when "object"
                     schema_example(schema)
                   when "array"
                     if schema.items && schema.items != schema_data
                       if schema.items.one_of
                         schema.items.one_of
                               .reject { |item| references.include?(item) }
                               .map { |item| schema_example(item, references + [item]) }
                       else
                         [schema_example(schema.items)]
                       end
                     else
                       []
                     end
                   when nil
                     if schema.all_of&.any?
                       schema_example(schema)
                     else
                       {}
                     end
                   else
                     Utils::primitive_schema_example(schema)
                   end
    end

    if schema_data.additional_properties?
      properties["<*>"] = if schema_data.additional_properties_schema
                            schema_example(schema_data.additional_properties_schema)
                          else
                            {}
                          end
    end

    properties
  end

  # @param [Openapi3Parser::Node::Schema] schema
  # @return [*]
  def get_schema_properties(schema)
    properties = schema.properties.to_h

    schema.all_of.to_a.each do |all_of_schema|
      properties.merge!(all_of_schema.properties.to_h)
    end

    properties
  end

  # @param [Openapi3Parser::Node::Schema] schema
  # @return [String]
  def render_schema_type(schema)
    if schema.one_of&.any?
      schemas = schema.one_of.map { |s| "<li>#{render_schema_type(s)}</li>" }
                      .join

      return "one of: <ul>#{schemas}</ul>"
    end

    if schema.type == "object"
      unless schema.name
        if schema.additional_properties? && schema.additional_properties_schema
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

      "array (#{render_schema_type(items)})"
    else
      if schema.name
        href = ::Middleman::Util::url_for(@app, "/schemas/#{schema.name}/index.html", {
          current_resource: current_resource
        })

        "<a href='#{href}'>#{schema.name}</a>"
      else
        # Make assumption that all oneOf items are same type as
        # Swashbuckle theoretically shouldn't allow different types.
        if schema.all_of&.any?
          return render_schema_type(schema.all_of[0])
        end

        schema.type || "any"
      end
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
