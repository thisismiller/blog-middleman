#!/usr/bin/env python
import livereload

server = livereload.Server()
server.watch('source/', livereload.shell('bundle exec middleman build --environment=development'))
server.serve(root='build/', port=4567)
