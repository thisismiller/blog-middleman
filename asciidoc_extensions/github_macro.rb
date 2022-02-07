require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include Asciidoctor

# An inline macro that turns github:foo/bar into a link to foo/bar on github.
#
# Usage
#
#   github:foo/bar[]
#   github:foo/bar[Bar]
#
class GitHubMacro < Extensions::InlineMacroProcessor
  use_dsl

  named :github
  parse_content_as :text

  def process parent, target, attrs
    url = %(https://github.com/#{target})
    if (text = attrs['text']).empty?
      text = target
    end
    text = text + 'image:https://github.com/favicon.ico[GitHub,14,14]'
    (create_anchor parent, text, type: :link, target: url).render 
  end
end

Asciidoctor::Extensions.register do
  inline_macro GitHubMacro
end
