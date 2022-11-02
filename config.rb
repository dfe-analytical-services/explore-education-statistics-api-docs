require 'govuk_tech_docs'
require 'lib/api_reference_pages_extension'
require 'lib/helpers'
require 'lib/api_reference_helpers'

# Check for broken links
require 'html-proofer'

GovukTechDocs.configure(self, livereload: { js_host: "localhost", host: "127.0.0.1" })

helpers Helpers
helpers ApiReferenceHelpers
activate :api_reference_pages

activate :relative_assets
set :relative_links, true

# Disable HTMLProofer until we can use absolute URLs.
# We currently have to use relative URLs to make this work on a GitHub Pages subdomain.
#
# after_build do |builder|
#   begin
#     HTMLProofer.check_directory(config[:build_dir],
#       {
#         :disable_external => true,
#         :swap_urls => {
#           config[:tech_docs][:host] => "",
#         }
#       }).run
#   rescue RuntimeError => e
#     abort e.to_s
#   end
# end
