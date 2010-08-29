require File.expand_path('../test_helper', __FILE__)

class ActionController::Base
  def render(*)
    yield
  end

  def params
    { :action => :show }
  end
end

class ArticlesController < ActionController::Base
  def article
    @article ||= Article.new
  end
end

class Article
  def initialize
    @attributes = { :title => '', :body => '' }
  end

  def id; 1 end
  def section; end

  def method_missing(name)
    @attributes[name]
  end
end

class ReferenceTrackingTest < Test::Unit::TestCase
  delegate :article, :to => :controller
  attr_reader :controller

  def setup
    @controller = ArticlesController.new
    controller.response = ActionDispatch::Response.new
  end

  def teardown
    ArticlesController.reference_tracking_options = nil
  end

  def references
    controller.instance_variable_get(:@_references)
  end

  test 'tracking a method' do
    ArticlesController.tracks :article
    controller.render { article }
    assert references.include?([article, nil])
  end

  test 'tracking a method on a tracked method' do
    ArticlesController.tracks :article => :title
    controller.render { article.title }
    assert references.include?([article, :title])
  end
end