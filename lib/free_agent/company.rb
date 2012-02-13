module FreeAgent
  class Company
    def initialize(domain, username, password)
      @resource = RestClient::Resource.new(
        "https://#{domain}.freeagent.com",
        :user => username, :password => password
      )
    end

    def invoices
      @invoices ||= Collection.new(@resource['/invoices'], :entity => :invoice)
    end

    def contacts
      @contacts ||= Collection.new(@resource['/contacts'], :entity => :contact)
    end

    def projects
      @projects ||= Collection.new(@resource['/projects'], :entity => :project)
    end

    def users
      @users ||= Collection.new(@resource['/company/users'], :entity => :user)
    end

    def bills(options={})
      if options.empty? && @bills
        @bills
      else
        convert_date_range!(options)
        @bills = Collection.new(@resource["/bills?view=#{options[:view]}"], :entity => :bill)
      end
    end

    # Note, this is only for PUT/POSTing to
    def timeslips
      @timeslips ||= Collection.new(@resource['/timeslips'], :entity => :timeslip)
    end

    def expenses(user_id, options={})
      convert_date_range_with_recent_default!(options)
      Collection.new(@resource["/users/#{user_id}/expenses?view=#{options[:view]}"], :entity => :expense, :key => [:bank_account_entries, :bank_transactions, :bank_transaction])
    end

    def bank_accounts
      @bank_accounts ||= Collection.new(@resource['/bank_accounts'], :entity => :bank_account, :key => :records)
    end

    def bank_transactions(bank_account_id, options={})
      convert_date_range_with_recent_default!(options)
      Collection.new(@resource["/bank_accounts/#{bank_account_id}/bank_account_entries?view=#{options[:view]}"], :entity => :bank_transaction, :key => [:bank_account_entries, :bank_transactions, :bank_transaction])
    end

    def dividends(options={})
      if options.empty? && @dividends
        @dividends
      else
        convert_date_range_with_recent_default!(options)
        @dividends ||= Collection.new(@resource["/accounting/dividends/#{options[:view]}"], :entity => :bank_account_entry, :key => [:bank_account_entries])
      end
    end

    private

    def convert_date_range_with_recent_default!(options)
      options.reverse_merge!(:view => 'recent')
      convert_date_range!(options)
    end

    def convert_date_range!(options)
      options.assert_valid_keys(:view, :from, :to)

      if options[:from] && options[:to]
        options[:view] = "#{options[:from].strftime('%Y-%m-%d')}_#{options[:to].strftime('%Y-%m-%d')}"
      end
    end
  end
end