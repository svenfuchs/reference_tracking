require 'active_support/core_ext/kernel/singleton_class'
require 'action_controller'

module ReferenceTracking
  autoload :ActionController, 'reference_tracking/action_controller'
  autoload :Proxy,            'reference_tracking/proxy'
  autoload :Tracker,          'reference_tracking/tracker'
  autoload :References,       'reference_tracking/references'
end

ActionController::Base.send(:extend, ReferenceTracking::ActionController::ActMacro)