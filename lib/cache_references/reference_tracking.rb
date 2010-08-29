require 'action_controller'
require 'cache_references/method_call_tracking'

module CacheReferences
  module ReferenceTracking
    TAGS_HEADER = 'rack-cache.tags'
    
    module ActMacro
      # Sets up reference tracking for given actions and objects
      # 
      #   tracks_references :index, :show, :track => [:article, :@articles, { :@site => :tag_counts }]
      #
      def tracks_references(*actions)
        unless tracks_cache_references?
          include ReferenceTracking
          
          class_inheritable_accessor :reference_tracking_options
          self.reference_tracking_options = { :header => TAGS_HEADER }
        end
    
        options = actions.extract_options!
        actions.map(&:to_sym).each do |action|
          self.reference_tracking_options[action] = options[:track]
        end
      end
  
      def tracks_cache_references?
        included_modules.include?(ReferenceTracking)
      end
    end
  
    protected
    
      def render(*)
        setup_reference_tracking
        result = super
        add_reference_headers
        result
      end
      
      def add_reference_headers
        headers[reference_tracking_options[:header]] = @reference_tracker.tags
      end

      def setup_reference_tracking
        @reference_tracker = MethodCallTracking::Tracker.new(self, reference_trackables)
      end
      
      def reference_trackables
        trackables = reference_tracking_options[params[:action].to_sym] || {}
        trackables.clone
      end
  end
end

ActionController::Base.send(:extend, CacheReferences::ReferenceTracking::ActMacro)