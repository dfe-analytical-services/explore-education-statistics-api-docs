class ApiReferencePagesExtension < Middleman::Extension
  expose_to_template :schema_example, :render_schema_type, :api_url

  def initialize(app, options_hash = {}, &block)
    super

    @sitemap = app.sitemap
    @config = app.config[:tech_docs]
    @endpoint_template = Middleman::Util.normalize_path("/endpoints/template.html")
    @schema_template = Middleman::Util.normalize_path("/schemas/template.html")

    app.ignore @endpoint_template
    app.ignore @schema_template
  end

  # @param [List<Middleman::Sitemap::Resource>] resources
  # @return [List<Middleman::Sitemap::Resource>]
  def manipulate_resource_list(resources)
    api_path = @config[:api_path]

    if api_path.nil?
      return resources
    end

    document = if uri?(api_path)
                 Openapi3Parser.load_url(api_path)
               elsif File.exist?(api_path)
                 # Load api file and set existence flag.
                 Openapi3Parser.load_file(api_path)
               else
                 raise "Unable to load api path from tech-docs.yml"
               end

    new_resources = []

    @base_url = document.servers[0]&.url || ""

    document.paths.each do |uri, http_methods|
      get_operations(http_methods).each do |http_method, operation|
        new_resources << create_endpoint_page(uri, http_method, operation)
      end
    end

    document.components.schemas.each do |_, schema|
      new_resources << create_schema_page(schema)
    end

    resources + new_resources
  end

  # @param [Openapi3Parser::Node::Schema] schema_data
  # @return [*]
  def schema_example(schema_data)
    if schema_data.example
      return schema_data.example
    end

    if is_primitive_schema(schema_data)
      return primitive_schema_example(schema_data)
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
                     primitive_schema_example(schema)
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
      "<a href='/schemas/#{schema.name}/'>#{schema.name}</a>"
    elsif schema.type == "array"
      items = schema.items

      if items.nil?
        return "array"
      end

      if items.type == "object" && items.name
        "array (<a href='/schemas/#{items.name}/'>#{items.name}</a>)"
      else
        "array (#{render_schema_type(items)})"
      end
    else
      schema.type || ""
    end
  end

  private

  # @param [String] uri
  # @param [String] http_method
  # @param [Openapi3Parser::Node::Operation] operation
  # @return [Middleman::Sitemap::ProxyResource]
  def create_endpoint_page(uri, http_method, operation)
    id = operation.operation_id

    Middleman::Sitemap::ProxyResource.new(
      @sitemap,
      Middleman::Util.normalize_path("/endpoints/#{id}/index.html"),
      @endpoint_template
    ).tap do |p|
      p.add_metadata locals: {
        title: operation.summary,
        url: api_url(uri),
        http_method: http_method.upcase,
        description: operation.description,
        parameters: operation.parameters,
        request_body: operation.request_body,
        responses: operation.responses
      }
    end
  end

  # @param [String] uri
  # @return [String]
  def api_url(uri = "")
    @base_url.chomp("/") + uri
  end

  private

  # @param [Openapi3Parser::Node::Schema] schema
  # @return [Middleman::Sitemap::ProxyResource]
  def create_schema_page(schema)
    name = schema.name

    Middleman::Sitemap::ProxyResource.new(
      @sitemap,
      Middleman::Util.normalize_path("/schemas/#{name}/index.html"),
      @schema_template
    ).tap do |p|
      p.add_metadata locals: {
        title: name,
        schema: schema,
      }
    end
  end

  # @param [Openapi3Parser::Node::PathItem] path
  # @return [Hash<String, Openapi3Parser::Node::PathItem>]
  def get_operations(path)
    {
      "get" => path.get,
      "put" => path.put,
      "post" => path.post,
      "delete" => path.delete,
      "patch" => path.patch,
    }.compact
  end

  # @param [Openapi3Parser::Node::Schema] schema
  # @return [String, Number, Boolean]
  def primitive_schema_example(schema)
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
  def is_complex_schema(schema)
    !!(schema.all_of || schema.any_of || schema.one_of || schema.not)
  end

  # @param [Openapi3Parser::Node::Schema] schema
  # @return [Boolean]
  def is_primitive_schema(schema)
    !is_complex_schema(schema) && !schema.type.nil? && schema.type != "object" && schema.type != "array"
  end

  # @param [String] string
  # @return [Boolean]
  def uri?(string)
    uri = URI.parse(string)
    %w[http https].include?(uri.scheme || "")
  rescue URI::BadURIError
    false
  rescue URI::InvalidURIError
    false
  end
end

Middleman::Extensions.register(:api_reference_pages, ApiReferencePagesExtension)
