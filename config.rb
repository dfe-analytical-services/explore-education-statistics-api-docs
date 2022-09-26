require 'govuk_tech_docs'
require 'lib/api_reference_pages_extension'
require 'lib/helpers'

# Check for broken links
require 'html-proofer'

GovukTechDocs.configure(self, livereload: { js_host: "localhost", host: "127.0.0.1" })

helpers Helpers
activate :api_reference_pages
activate :directory_indexes

after_build do |builder|
  begin
    HTMLProofer.check_directory(config[:build_dir],
      {
        :disable_external => true,
        :allow_hash_href => true,
        :empty_alt_ignore => true,
        :url_swap => { config[:tech_docs][:host] => "" }
      }).run
  rescue RuntimeError => e
    abort e.to_s
  end
end
