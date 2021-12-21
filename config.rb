# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

activate :autoprefixer do |prefix|
  prefix.browsers = "last 2 versions"
end

require 'asciidoctor-diagram'
activate :asciidoc, safe: :unsafe, attributes: ['source-highlighter=coderay']
set :skip_build_clean, proc {|f| f.start_with? 'build/images/'}

class ImageDirPerAsciidoc < Middleman::Extension
  def initialize(app, options_hash={}, &block)
    super
  end

  def manipulate_resource_list(resources)
    resources.each do |resource|
      if resource.source_file.end_with? '.adoc'
        resource.options[:renderer_options][:attributes]['imagesdir'] = ::File.join(@app.config[:asciidoc][:attributes]['imagesdir'].chomp('@'), resource.page_id + "@")
        resource.options[:renderer_options][:attributes]['imagesoutdir'] = ::File.join(@app.config[:asciidoc][:attributes]['site-destination'], @app.config[:images_dir], resource.page_id + "@")
      end
    end

    resources
  end
end

::Middleman::Extensions.register(:imagedir_per_asciidoc, ImageDirPerAsciidoc)
activate :imagedir_per_asciidoc

# Layouts
# https://middlemanapp.com/basics/layouts/

# Per-page layout changes
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page '/path/to/file.html', layout: 'other_layout'

# Proxy pages
# https://middlemanapp.com/advanced/dynamic-pages/

# proxy(
#   '/this-page-has-no-template.html',
#   '/template-file.html',
#   locals: {
#     which_fake_page: 'Rendering a fake page with a local variable'
#   },
# )

# Helpers
# Methods defined in the helpers block are available in templates
# https://middlemanapp.com/basics/helper-methods/

# helpers do
#   def some_helper
#     'Helping'
#   end
# end

# Build-specific configuration
# https://middlemanapp.com/advanced/configuration/#environment-specific-settings

configure :ghpages do
  set :http_prefix, "/blog-middleman"
  activate :minify_css
  activate :minify_javascript
end

configure :transactionalblog do
  activate :minify_css
  activate :minify_javascript
end

# configure :build do
#   activate :minify_css
#   activate :minify_javascript
# end
