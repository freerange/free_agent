module FreeAgent
  class User < Entity
    has_many :expenses
    has_many :timeslips
  end
end