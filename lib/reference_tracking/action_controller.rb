module ReferenceTracking
  module ActionController
    TAGS_HEADER = 'rack-cache.tags'

    module ActMacro
      def tracks(*args)
        unless tracks_references?
          include ReferenceTracking::ActionController

          class_inheritable_accessor :reference_tracking_options
          self.reference_tracking_options = { :header => TAGS_HEADER }
        end

        options = args.extract_options!
        actions = (options[:only] || [:index, :show]) - (options[:except] || [])
        args.each { |arg| options[arg] = nil }

        actions.map(&:to_sym).each do |action|
          self.reference_tracking_options[action] = options
        end
      end

      def tracks_references?
        respond_to?(:reference_tracking_options) && reference_tracking_options.present?
      end
    end

    def render(*)
      setup_reference_tracking
      result = super
      store_reference_tag_headers
      result
    end

    protected

      def setup_reference_tracking
        methods = reference_tracking_options[params[:action].to_sym] || {}
        @_references = ReferenceTracking::References.new(self, methods)
      end

      def store_reference_tag_headers
        headers[reference_tracking_options[:header]] = @_references.tags
      end
  end
end