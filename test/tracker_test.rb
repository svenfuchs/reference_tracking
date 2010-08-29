require File.expand_path('../test_helper', __FILE__)

class TrackerTest < Test::Unit::TestCase
  include ReferenceTracking

  class Object
    def foo; @foo ||= Foo.new end
    def bar; end
  end
  
  class Foo
    def bar; @bar ||= Bar.new end
  end
  
  class Bar
    def baz; end
  end

  attr_reader :object, :references

  def setup
    @object = Object.new
    @references = []
  end

  test "tracker_for returns the tracker tracker module for the given object" do
    tracker = Tracker.tracker_for(object)
    assert_equal object.singleton_class.const_get(:ReferenceTracker), tracker
    assert_equal tracker.object_id, Tracker.tracker_for(object).object_id
  end

  test "tracker_for returns a unique tracker tracker module for each object" do
    assert_not_equal Tracker.tracker_for(Object.new).object_id, Tracker.tracker_for(Object.new).object_id
  end

  test "setup_tracking makes the object track calls to a given method" do
    Tracker.setup(object, references, :foo)
    foo = object.foo
    assert_equal [[foo, nil]], references
  end

  test "setup_tracking makes the object track calls to methods given as an Array" do
    Tracker.setup(object, references, [:foo, :bar])
    foo = object.foo
    bar = object.bar
    assert_equal [[foo, nil], [bar, nil]], references
  end

  test "setup_tracking makes the object track calls to a given nested method hash" do
    Tracker.setup(object, references, :foo => { :bar => :baz })
    object.foo.bar.baz
    assert_equal [[object.foo.bar, :baz]], references
  end

  test "setup_tracking looks up a given ivar on the object and makes it track calls on the object" do
    object.instance_variable_set(:@foo, Foo.new)
    Tracker.setup(object, references, :@foo)
    foo = object.instance_variable_get(:@foo)
    foo.bar
    assert_equal [[foo, nil]], references
  end

  test "setup_tracking looks up a given ivar on the object and makes it track calls to a given method" do
    foo = object.instance_variable_set(:@foo, Foo.new)
    Tracker.setup(object, references, :@foo => :bar)
    foo.bar
    assert_equal [[foo, :bar]], references
  end
end