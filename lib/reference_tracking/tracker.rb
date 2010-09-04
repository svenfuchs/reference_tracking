# tracks :post                    # => tags post-1.*
# tracks 'post.title'             # => tags post-1.title
# tracks :post => :blog           # => tags blog-1.*
# tracks :blog => :posts          # => tags post-1.*, post-1.*, ...

require 'active_support/core_ext/array/wrap'

module ReferenceTracking
  module Tracker
    class << self
      def setup(object, references, targets, options = {})
        Array.wrap(targets).each do |target|
          if target.is_a?(Hash)
            target.each { |target, nested| delegate_tracking(object, references, target, nested) }
          elsif options[:delegated]
            send(options[:delegated], object, references, target)
          elsif target.to_s.include?('.')
            delegate_tracking(object, references, *target.to_s.split('.') << :track_calls_to)
          else
            track_calls_on(object, references, target)
          end
        end
      end

      def tracker_for(object)
        Module.new.tap { |tracker| object.singleton_class.send(:include, tracker) }
      end

      def track_calls_on(object, references, target)
        tracker_for(object).send(:define_method, target) do |*args|
          super.tap { |object| Array(object).each { |object| references << [object, nil] } }
        end
      end

      def track_calls_to(object, references, method)
        method = method.to_s.split('.').last if method.to_s.include?('.')
        tracker_for(object).send(:define_method, method) do |*args|
          references << [self, method]
          super
        end
      end

      def delegate_tracking(object, references, target, delegateds, method = :track_calls_on)
        tracker_for(object).send(:define_method, target) do |*|
          super.tap do |object| 
            Array.wrap(delegateds).each do |delegated|
              delegated = [delegated] if delegated.is_a?(Hash)
              _method = delegated.to_s.start_with?('.') ? :track_calls_to : method
              Tracker.setup(object, references, delegated, :delegated => _method)
            end
          end
        end
      end
    end
  end
end