require File.expand_path('../test_helper', __FILE__)

class ReferencesTest < Test::Unit::TestCase
  include ReferenceTracking

  class Controller
    def foo; @foo ||= Foo.new end
  end

  class Foo
    def id; 1 end
  end

  attr_reader :controller, :references, :foo

  def setup
    @controller = Controller.new
    @references = References.new(controller, :foo)
    @foo = controller.foo
  end

  test "sets up reference tracking for the given object and methods" do
    assert_equal [[foo, nil]], references
  end

  test "generates tags from the collected references" do
    assert_equal ['references_test/foo-1'], references.tags
  end
end