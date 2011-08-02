require "rubygems"
require "bundler/setup"

require "yaml"
require "free_agent"

successful = true
config = YAML.load(File.open("config.yml"))
FreeRange = FreeAgent::Company.new(config[:domain], config[:username], config[:password])
FreeRange.bank_accounts.each do |account|
  FreeRange.bank_transactions(account.id, :from => Date.parse("2010-10-31"), :to => Date.today).each do |transaction|
    if %r{USD|\$}.match(transaction.name)
      transaction.bank_account_entries.each do |entry|
        if entry.sales_tax_rate > 0
          successful = false
          puts [account.name, transaction.dated_on.to_date, transaction.name, entry.sales_tax_rate.to_f].join("\t")
        end
      end
    end
  end
end

abort 'some USD transactions with non-zero VAT were found' unless successful