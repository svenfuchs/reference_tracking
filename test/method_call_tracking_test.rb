require File.expand_path('../test_helper', __FILE__)

class MethodCallTrackingTest < Test::Unit::TestCase
  include CacheReferences

  attr_reader :object, :tracker, :references

  class Object
    include CacheReferences::MethodCallTracking

    def title; end
    def foo(bar, baz); end
  end

  def setup
    @tracker = MethodCallTracking::Tracker.new
    @object = Object.new
    @references = []
  end

  test 'Tracker#resolve_trackable resolves ivars given as symbols' do
    object.expects(:instance_variable_get).with(:@foo)
    tracker.send(:resolve_trackable, object, :@foo)
  end

  test 'Tracker#resolve_trackable resolves ivars given as strings' do
    object.expects(:instance_variable_get).with(:@foo)
    tracker.send(:resolve_trackable, object, '@foo')
  end

  test 'Tracker#resolve_trackable resolves method_names given as symbols' do
    object.expects(:foo)
    tracker.send(:resolve_trackable, object, :foo)
  end

  test 'Tracker#resolve_trackable resolves method_names given as strings' do
    object.expects(:foo)
    tracker.send(:resolve_trackable, object, 'foo')
  end

  test 'Tracker#track resolves trackables given as a symbol, string or hash key' do
    [:@foo, :@bar].each { |ivar| object.expects(:instance_variable_get).with(ivar) }
    [:baz, :buz, :bum].each { |method| object.expects(method) }

    tracker.track(object, [:@foo, '@bar', :baz, 'buz', { :bum => nil }])
  end

  test 'Tracker#track tracks read_attribute method when the given method is an attribute' do
    foo = stub('foo', :has_attribute? => true)
    object.expects(:foo).returns(foo)

    foo.expects(:track_method_calls).with([], [:read_attribute])
    tracker.track(object, [:foo])
  end

  test 'Tracker#track tracks the given method when it is not an attribute' do
    foo = stub('foo', :has_attribute? => false)
    object.expects(:foo).returns(foo)

    foo.expects(:track_method_calls).with([], [:bar])
    tracker.track(object, [{ :foo => :bar }])
  end

  test 'track_method_calls installs on methods that do no take any arguments' do
    assert_nothing_raised {
      object.track_method_calls(references, [:title])
      object.title
    }
  end

  test 'track_method_calls installs on methods that take arguments' do
    assert_nothing_raised {
      object.track_method_calls(references, [:foo])
      object.foo(:bar, :baz)
    }
  end

  test "track_method_calls installs a new method on the object's meta class" do
    object.track_method_calls(references, [:title])
    assert (class << object; self; end).method_defined?(:title)
  end

  test "a call to a tracked method adds a reference to the given references array" do
    object.track_method_calls(references, [:title])
    object.title
    assert_equal [object, :title], references.first
  end

  test "subsequent calls to the same tracked method do not add multiple references" do
    object.track_method_calls(references, [:title])
    object.title
    object.title
    assert_equal [object, :title], references.first
  end

  test "tracking can be set up multiple times for the same method" do
    assert_nothing_raised {
      object.track_method_calls(references, [:title])
      object.track_method_calls(references, [:title])
    }
    object.title
    object.title
    assert_equal [object, :title], references.first
  end
end
