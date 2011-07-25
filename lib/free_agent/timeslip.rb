module FreeAgent
  class Timeslip < Entity
    def initialize(resource, attributes={})
      # need to convert /projects/123/timeslips/456 into /timeslips/456
      tweaked_resource = RestClient::Resource.new(resource.url.gsub(/\/projects\/\d+\//, "/"), resource.options)
      super(tweaked_resource, attributes)
    end

    belongs_to :project
    belongs_to :user
    belongs_to :task
  end
end