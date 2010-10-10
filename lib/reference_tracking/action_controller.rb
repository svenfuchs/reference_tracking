require 'active_support/core_ext/array/grouping'

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
      SKIP_ATTRIBUTES = %w(id created_at updated_at)

      def purge(objects)
        tags = objects.map { |object| purge_tags_for(object)  }.flatten
        response.headers[purging_options[:header]] = tags
      end

      def purge_tags_for(object)
        case params[:action]
        when 'create', 'destroy'
          tags = purge_associations_for(object).map do |owner, method|
            ReferenceTracking.to_tag(owner, method)
          end
          tags << ReferenceTracking.to_tag(object) if params[:action] == 'destroy'
          tags
        when 'update'
          methods = object.previous_changes.keys & object.attributes.keys - SKIP_ATTRIBUTES
          methods.map { |method| ReferenceTracking.to_tag(object, method) }
        end
      end

      def purge_associations_for(object)
        superclasses = purge_super_classes_for(object)
        object.class.reflect_on_all_associations(:belongs_to).map do |association|
          if owner = object.send(association.name)
            owner.class.reflect_on_all_associations.map do |association|
              [owner, association.name] if superclasses.include?(association.class_name)
            end
          end
        end.flatten.compact.in_groups_of(2)
      end

      def purge_super_classes_for(object)
        object.class.ancestors.select { |klass| klass < ActiveRecord::Base }.map(&:name)
      end
    end
  end
end
