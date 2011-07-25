require 'restclient'
require 'crack'
require 'hashie'

# see https://rails.lighthouseapp.com/projects/8994/tickets/5630
require 'active_support/lazy_load_hooks'

require 'active_support/core_ext/string'
require 'active_support/core_ext/object/returning'
require 'active_support/core_ext/hash'
require 'cgi'

RestClient::Resource.class_eval do
  def root
    self.class.new(URI.parse(url).merge('/').to_s, options)
  end
end

module FreeAgent

  autoload :Attachment, 'free_agent/attachment'
  autoload :BankAccount, 'free_agent/bank_account'
  autoload :BankAccountEntry, 'free_agent/bank_account_entry'
  autoload :BankTransaction, 'free_agent/bank_transaction'
  autoload :Bill, 'free_agent/bill'
  autoload :Collection, 'free_agent/collection'
  autoload :Company, 'free_agent/company'
  autoload :Contact, 'free_agent/contact'
  autoload :Entity, 'free_agent/entity'
  autoload :Expense, 'free_agent/expense'
  autoload :Invoice, 'free_agent/invoice'
  autoload :InvoiceItem, 'free_agent/invoice_item'
  autoload :Project, 'free_agent/project'
  autoload :Task, 'free_agent/task'
  autoload :Timeslip, 'free_agent/timeslip'
  autoload :User, 'free_agent/user'

end