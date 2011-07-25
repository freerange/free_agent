module FreeAgent
  class Invoice < Entity
    has_many :invoice_items
    belongs_to :project
    belongs_to :contact
  end
end