module FreeAgent
  class Bill < Entity
    belongs_to :contact
    belongs_to :project, :key => :rebilled_to_project_id
  end
end