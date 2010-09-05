module ReferenceTracking
  module ActionController
    module ActMacro
      def tracks(*args)
        unless tracks_references?
          include ReferenceTracking::ActionController::Tracking

          class_inheritable_accessor :reference_tracking_options
          self.reference_tracking_options = { :header => TAGS_HEADER }
        end

        options = args.extract_options!
        actions = Array(options.delete(:only) || [:index, :show]) - Array(options.delete(:except))
        args << options unless options.empty?

        actions.map(&:to_sym).each do |action|
          self.reference_tracking_options[action] ||= []
          self.reference_tracking_options[action] += args
        end
      end

      def tracks_references?
        respond_to?(:reference_tracking_options) && reference_tracking_options.present?
      end

      def purges(*actions)
        unless purges?
          include ReferenceTracking::ActionController::Purging
          class_inheritable_accessor :purging_options
          self.purging_options = { :header => PURGE_TAGS_HEADER, :actions => [] }
        end

        self.purging_options[:actions] += actions.map(&:to_sym)
        self.purging_options[:actions].uniq
      end

      def purges?
        respond_to?(:purging_options)
      end

      def purge?(action)
        purges? && purging_options[:actions].include?(action.to_sym)
      end
    end

    # TODO could this hook into instrumentation?
    # ActiveSupport::Notifications.instrument("render_template.action_view", ...)?

    module Tracking
      def render(*)
        methods = reference_tracking_options[params[:action].to_sym] || {}
        @_references = ReferenceTracking::References.new(self, methods)

        result = super

        headers[reference_tracking_options[:header]] = @_references.tags unless @_references.empty?
        result
      end
    end

    module Purging
      def purge(objects)
        response.headers[purging_options[:header]] = objects.map { |object| ReferenceTracking.to_tag(object) }
      end
    end
  end
end