module ReferenceTracking
  class References < Array
    def initialize(object, methods)
      Tracker.setup(object, self, methods)
    end

    def tags
      uniq.map { |object, method| ReferenceTracking.to_tag(object, method) }
    end
  end
end