module FreeAgent
  class BankAccountEntry < Entity
    belongs_to :bank_account
    belongs_to :bank_transaction
  end
end