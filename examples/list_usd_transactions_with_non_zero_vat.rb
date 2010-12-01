require "yaml"
require "rubygems"
require "free_agent"

config = YAML.load(File.open("config.yml"))
FreeRange = FreeAgent::Company.new(config[:domain], config[:username], config[:password])
FreeRange.bank_accounts.each do |account|
  FreeRange.bank_transactions(account.id, :from => Date.parse("2010-01-01"), :to => Date.parse("2010-11-30")).each do |transaction|
    if transaction.name[/USD|\$/]
      transaction.bank_account_entries.each do |entry|
        if entry.sales_tax_rate > 0
          puts [account.name, transaction.dated_on.to_date, transaction.name, entry.sales_tax_rate.to_f].join("\t")
        end
      end
    end
  end
end
