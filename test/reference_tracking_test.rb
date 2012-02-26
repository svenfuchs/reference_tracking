require File.expand_path('../test_helper', __FILE__)

class ActionController::Base
  def render(*); yield end
  def params; { :action => :show } end
end

class PostsController < ActionController::Base
  def blog; @blog ||= Blog.new end
  def post; @post ||= Post.new end
end

class Record
  undef_method :id rescue nil
  def initialize; @attributes = { :id => 1, :title => '' } end
  def method_missing(name); @attributes[name] end
end

class Blog < Record
end

class Post < Record
  def blog; @blog ||= Blog.new end
end

class ReferenceTrackingTest < Test::Unit::TestCase
  delegate :blog, :post, :to => :controller
  attr_reader :controller

  def setup
    @controller = PostsController.new
    controller.response = ActionDispatch::Response.new
  end

  def teardown
    PostsController.reference_tracking_options = nil
  end

  def references
    controller.instance_variable_get(:@_references)
  end

  def assert_tracks(expected)
    actual = PostsController.reference_tracking_options.except(:header)
    assert_equal expected, actual
  end

  test 'tracking a single method' do
    PostsController.tracks :post
    assert_tracks(:index => [:post], :show => [:post])
    controller.render { post.title }
    assert_equal %w(post-1), references.tags
  end

  test 'tracking a single method on a specific action' do
    PostsController.tracks :post, :only => :show
    assert_tracks(:show => [:post])
    controller.render { post.title }
    assert_equal %w(post-1), references.tags
  end

  test 'tracking a single method excluding a specific action' do
    PostsController.tracks :post, :except => :show
    assert_tracks(:index => [:post] )
    controller.render { post.title }
    assert_equal %w(), references.tags
  end

  test 'tracking a nested method' do
    PostsController.tracks :post => { :blog => '.title' }, :only => :show
    assert_tracks(:show => [{ :post => { :blog => '.title' } }])
    controller.render { post.blog.title }
    assert_equal %w(blog-1:title), references.tags
  end

  test 'tracking an array of methods on a target (1)' do
    PostsController.tracks :post => %w(.title .body), :only => :show
    assert_tracks(:show => [{ :post => %w(.title .body) }])
    controller.render { post.title; post.body }
    assert_equal %w(post-1:title post-1:body), references.tags
  end

  test 'tracking an array of methods on a target (2)' do
    PostsController.tracks :post => %w(.title .body), :only => :show
    assert_tracks(:show => [{ :post => %w(.title .body) }])
    controller.render { post.body; post.title }
    assert_equal %w(post-1:body post-1:title), references.tags
  end

  # test 'tracking an array of methods' do
  #   PostsController.tracks [:blog, :post], :only => :show
  #   assert_tracks(:show => [[:blog, :post]])
  #   controller.render { post.title; blog.title }
  #   assert_equal %w(post-1 blog-1), references.tags
  # end
  #
  # test 'tracking a method on an array of methods' do
  #   PostsController.tracks [:blog, :post] => :title, :only => :show
  #   assert_tracks(:show => [{ [:blog, :post] => :title }])
  #   controller.render { post.title; blog.title }
  #   assert_equal %w(post-1:title blog-1:title), references.tags
  # end
end
