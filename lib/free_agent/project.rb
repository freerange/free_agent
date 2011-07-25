module FreeAgent
  class Project < Entity
    has_many :tasks
    has_many :invoices
    has_many :timeslips
    belongs_to :contact

    def active?
      status == "Active"
    end
  end
end