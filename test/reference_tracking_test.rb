require File.expand_path('../test_helper', __FILE__)

class ReferenceTrackingTest < Test::Unit::TestCase
  attr_reader :controller, :article, :comment
  
  def setup
    @article = Article.new
    @comment = Comment.new

    @controller = ArticlesController.new
    @controller.instance_variable_set(:@article, @article)
    @controller.instance_variable_set(:@comments, [@comment])
  end
  
  def tracker
    controller.instance_variable_get(:@reference_tracker)
  end
  
  test 'accessing an attribute on an observed object records the reference' do
    controller.process { article.title }
    assert tracker.references.include?([article, :read_attribute])
  end
  
  test 'accessing a registered method on an observed object records the reference' do
    controller.process { article.section }
    assert tracker.references.include?([article, :section])
  end
  
  test 'accessing an attribute on an observed array of objects records the reference' do
    controller.process { comment.body }
    assert tracker.references.include?([comment, :read_attribute])
  end
  
  test 'accessing a registered method on an observed array of objects records the reference' do
    controller.process { comment.section }
    assert tracker.references.include?([comment, :section])
  end
  
  test 'adds reference tags to the headers hash' do
    controller.process { article.title; comment.section; comment.body }
    assert_equal 'article-1,comment-2', controller.headers[CacheReferences::ReferenceTracking::TAGS_HEADER]
  end
end