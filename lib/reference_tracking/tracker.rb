module ReferenceTracking
  module Tracker
    class << self
      def included(base)
        base.extend(ClassMethods)
      end

      def setup(object, references, targets)
        targets = { targets => nil } unless targets.is_a?(Hash)
        tracker_for(object).track_targets(object, references, targets)
      end

      def tracker_for(object)
        const, name = object.singleton_class, :ReferenceTracker
        tracker = const.const_defined?(name) ? const.const_get(name) : const.const_set(name, TRACKER.dup)
        object.singleton_class.send(:include, tracker)
        tracker
      end
    end

    module ClassMethods
      def track_targets(object, references, targets)
        targets.each do |target, method|
          Array(target).each do |target|
            if target.to_s[0, 1] == '@'
              track_ivar(object, references, target, method)
            else
              track_target(object, references, target, method)
            end
          end
        end
      end

      def track_ivar(owner, references, name, method)
        object = owner.instance_variable_get(name)
        if method
          Tracker.tracker_for(object).track_calls_on(references, method)
        else
          owner.instance_variable_set(name, Proxy.new(owner, name, object, references))
        end
      end

      def track_target(object, references, target, method)
        case method
        when NilClass, Symbol, String
          track_calls_to(references, target, method)
        when Hash
          track_nested(references, target, method)
        end
      end

      def track_calls_to(references, target, method)
        define_method(target) do |*args|
          reference_tracking.send(:remove_method, target)
          super.tap { |object| references << [object, method] }
        end
      end

      def track_calls_on(references, target)
        define_method(target) do |*args|
          reference_tracking.send(:remove_method, target)
          references << [self, target]
          super
        end
      end

      def track_nested(references, target, nested)
        define_method(target) do |*|
          reference_tracking.send(:remove_method, target)
          super.tap { |object| Tracker.setup(object, references, nested) }
        end
      end
    end

    TRACKER = Module.new.tap { |m| m.send(:include, Tracker) }

    def reference_tracking
      Tracker.tracker_for(self)
    end
  end
end