#!/usr/bin/env python
import livereload

server = livereload.Server()
middleman_build = livereload.shell('bundle exec middleman build --environment=development')
middleman_build()
server.watch('source/', middleman_build)
server.watch('config.rb', middleman_build)
server.watch('asciidoc_extensions', middleman_build)
server.watch('asciidoc_templates', middleman_build)
server.serve(root='build/', port=4567)
