module FreeAgent
  class Expense < Entity
    belongs_to :user
  end
end