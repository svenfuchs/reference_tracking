# tracks :post                    # => tags post-1.*
# tracks 'post.title'             # => tags post-1.title
# tracks :post => :blog           # => tags blog-1.*
# tracks :blog => :posts          # => tags post-1.*, post-1.*, ...

require 'active_support/core_ext/array/wrap'

module ReferenceTracking
  module Tracker
    class << self
      def included(base)
        base.extend(ClassMethods)
      end

      def setup(object, references, targets, options = {})
        tracker_for(object).track(object, references, targets, options)
      end

      def tracker_for(object)
        const, name = object.singleton_class, :ReferenceTracker
        tracker = const.const_defined?(name) ? const.const_get(name) : const.const_set(name, TRACKER.dup)
        object.singleton_class.send(:include, tracker) unless object.singleton_class.included_modules.include?(tracker)
        tracker
      end
    end

    module ClassMethods
      def track(object, references, targets, options)
        Array.wrap(targets).each do |target|
          if target.is_a?(Hash)
            target.each { |target, nested| delegate_tracking(references, target, nested) }
          elsif options[:delegated]
            send(options[:delegated], references, target)
          elsif target.to_s.include?('.')
            delegate_tracking(references, *target.to_s.split('.') << :track_calls_to)
          else
            track_calls_on(references, target)
          end
        end
      end

      def track_calls_on(references, target)
        define_method(target) do |*args|
          # Tracker.tracker_for(self).send(:remove_method, target)
          super.tap { |object| Array(object).each { |object| references << [object, nil] } }
        end
      end

      def track_calls_to(references, method)
        method = method.to_s.split('.').last if method.to_s.include?('.')
        define_method(method) do |*args|
          # Tracker.tracker_for(self).send(:remove_method, method)
          references << [self, method]
          super
        end
      end

      def delegate_tracking(references, target, delegated, method = :track_calls_on)
        define_method(target) do |*|
          # Tracker.tracker_for(self).send(:remove_method, target)
          super.tap { |object| 
            Array.wrap(delegated).each do |delegated|
              delegated = [delegated] if delegated.is_a?(Hash)
              _method = delegated.to_s.start_with?('.') ? :track_calls_to : method
              Tracker.setup(object, references, delegated, :delegated => _method)
            end
           }
        end
      end
    end

    TRACKER = Module.new.tap { |m| m.send(:include, Tracker) }
  end
end