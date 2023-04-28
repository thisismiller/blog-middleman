# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

require_relative 'asciidoc_extensions/string_ext'

activate :autoprefixer do |prefix|
  prefix.browsers = "last 2 versions"
end

require 'asciidoctor-diagram'
require_relative 'asciidoc_extensions/inline_macros'
require_relative 'asciidoc_extensions/ophistory_diagram'
activate :asciidoc, safe: :unsafe, template_dirs: 'asciidoc_templates', attributes: ['source-highlighter=rouge', 'toc-title=']
set :skip_build_clean, proc {|f| f.start_with? 'build/images/'}

class ImageDirPerAsciidoc < Middleman::Extension
  def initialize(app, options_hash={}, &block)
    super
  end

  def manipulate_resource_list(resources)
    resources.each do |resource|
      if resource.source_file.end_with? '.adoc'
        resource.options[:renderer_options][:attributes]['icons'] = 'font'
        resource.options[:renderer_options][:attributes]['imagesdir'] = ::File.join(@app.config[:asciidoc][:attributes]['imagesdir'].chomp('@'), resource.page_id + "@")
        resource.options[:renderer_options][:attributes]['imagesoutdir'] = ::File.join(@app.config[:asciidoc][:attributes]['site-destination'], @app.config[:images_dir], resource.page_id + "@")
      end
    end

    resources
  end
end

::Middleman::Extensions.register(:imagedir_per_asciidoc, ImageDirPerAsciidoc)
activate :imagedir_per_asciidoc

require 'nokogiri'
activate :blog do |blog|
  blog.sources = "{category}/{title}.html"
  blog.permalink = "{category}/{title}.html"
  blog.default_extension = ".adoc"
  blog.summary_length = nil
  blog.summary_generator = Proc.new { |article, rendered, length, ellipsis|
    f = Nokogiri::HTML(rendered).at('body > #preamble')
    if f
      f.children.map(&:to_html).join()
    else
      Nokogiri::HTML(rendered).at('body > p')&.to_html
    end
  }
end

# Layouts
# https://middlemanapp.com/basics/layouts/

# Per-page layout changes
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

ignore /.*\.swp/

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

require 'terser'

configure :ghpages do
  set :http_prefix, "/blog-middleman"
  activate :minify_css
  activate :minify_javascript, compressor: Terser.new
end

configure :transactionalblog do
  set :http_prefix, "/"
  activate :minify_css
  activate :minify_javascript, compressor: Terser.new
end
