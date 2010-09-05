require 'active_support/core_ext/kernel/singleton_class'
require 'action_controller'

module ReferenceTracking
  TAGS_HEADER       = 'rack-cache.tags'
  PURGE_TAGS_HEADER = 'rack-cache.purge-tags'

  autoload :ActionController, 'reference_tracking/action_controller'
  autoload :IvarProxy,        'reference_tracking/ivar_proxy'
  autoload :Tracker,          'reference_tracking/tracker'
  autoload :References,       'reference_tracking/references'

  class << self
    def to_tag(object, method = nil)
      "#{object.class.name.underscore}-#{object.id}#{":#{method}" if method}"
    end
  end
end

ActionController::Base.send(:extend, ReferenceTracking::ActionController::ActMacro)