module ReferenceTracking
  module ActionController
    module ActMacro
      def tracks(*args)
        unless tracks_references?
          include ReferenceTracking::ActionController

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
    end

    # TODO could this hook into instrumentation?
    # ActiveSupport::Notifications.instrument("render_template.action_view", ...)?

    def render(*)
      methods = reference_tracking_options[params[:action].to_sym] || {}
      @_references = ReferenceTracking::References.new(self, methods)

      result = super

      headers[reference_tracking_options[:header]] = @_references.tags
      result
    end
  end
end