$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'test/unit'
require 'mocha'
require 'test_declarative'
require 'ruby-debug'
require 'reference_tracking'

# class Comment < Record
#   def initialize
#     @attributes = { :body => '' }
#   end
#
#   def id
#     2
#   end
# end

