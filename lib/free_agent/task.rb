module FreeAgent
  class Task < Entity
    belongs_to :project
  end
end