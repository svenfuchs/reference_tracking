require File.expand_path('../test_helper', __FILE__)

class ReferencesTest < Test::Unit::TestCase
  include ReferenceTracking

  class Controller
    def foo; @foo ||= Foo.new end
    def bar; @bar ||= Bar.new end
  end

  class Foo
    def id; 1 end
  end

  class Bar
    def id; 1 end
    def baz; 1 end
  end

  attr_reader :controller, :references

  def setup
    @controller = Controller.new
    @references = References.new(controller, [:foo, 'bar.baz'])
  end

  test "sets up reference tracking for the given object and methods" do
    foo = controller.foo
    assert_equal [[foo, nil]], references
  end

  test "generates tags from the collected references" do
    foo = controller.foo
    assert_equal ['references_test/foo-1'], references.tags
  end

  test "generates tags from the collected references 2" do
    bar = controller.bar.baz
    assert_equal ['references_test/bar-1:baz'], references.tags
  end
end