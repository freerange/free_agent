module FreeAgent
  class Contact < Entity
    has_many :invoices
    has_many :projects
  end
end