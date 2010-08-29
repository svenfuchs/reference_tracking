$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'test/unit'
require 'mocha'
require 'test_declarative'

require 'cache_references/reference_tracking'
require 'cache_references'

class ActionController::Base
  def render(*)
    yield
  end
end

class ArticlesController < ActionController::Base
  tracks_references :show, :track => [:@article, :@comments, { :@article => :section, :@comments => :section }]

  def process(&block)
    self.response = ActionDispatch::Response.new
    run_callbacks(:process_action, :show) { render(&block) }
  end

  def params
    { :action => :show }
  end
end

class Record
  include CacheReferences::MethodCallTracking
  
  def section; end

  def read_attribute(name)
    @attributes[name]
  end

  def method_missing(name)
    read_attribute(name)
  end
end

class Article < Record
  def initialize
    @attributes = {:title => '', :body => ''}
  end
  
  def id
    1
  end
end

class Comment < Record
  def initialize
    @attributes = {:body => ''}
  end
  
  def id
    2
  end
end

