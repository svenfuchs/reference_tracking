# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'reference_tracking/version'

Gem::Specification.new do |s|
  s.name         = "reference_tracking"
  s.version      = ReferenceTracking::VERSION
  s.authors      = ["Sven Fuchs"]
  s.email        = "svenfuchs@artweb-design.de"
  s.homepage     = "http://github.com/svenfuchs/reference_tracking"
  s.summary      = "[summary]"
  s.description  = "[description]"

  s.files        = `git ls-files app lib`.split("\n")
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'
  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'activesupport'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'test_declarative'
end
