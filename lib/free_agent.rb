require 'restclient'
require 'crack'
require 'mash'

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
  class Company
    def initialize(domain, username, password)
      @resource = RestClient::Resource.new(
        "https://#{domain}.freeagentcentral.com",
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

    # Note, this is only for PUT/POSTing to
    def timeslips
      @timeslips ||= Collection.new(@resource['/timeslips'], :entity => :timeslip)
    end

    def expenses(user_id, options={})
      options.assert_valid_keys(:view, :from, :to)
      options.reverse_merge!(:view => 'recent')

      if options[:from] && options[:to]
        options[:view] = "#{options[:from].strftime('%Y-%m-%d')}_#{options[:to].strftime('%Y-%m-%d')}"
      end

      Collection.new(@resource["/users/#{user_id}/expenses?view=#{options[:view]}"], :entity => :expense, :key => [:bank_account_entries, :bank_transactions, :bank_transaction])
    end

    def bank_accounts
      @bank_accounts ||= Collection.new(@resource['/bank_accounts'], :entity => :bank_account, :key => :records)
    end

    def bank_transactions(bank_account_id, options={})
      options.assert_valid_keys(:view, :from, :to)
      options.reverse_merge!(:view => 'recent')

      if options[:from] && options[:to]
        options[:view] = "#{options[:from].strftime('%Y-%m-%d')}_#{options[:to].strftime('%Y-%m-%d')}"
      end

      Collection.new(@resource["/bank_accounts/#{bank_account_id}/bank_account_entries?view=#{options[:view]}"], :entity => :bank_transaction, :key => [:bank_account_entries, :bank_transactions, :bank_transaction])
    end
  end

  class Collection
    include Enumerable

    def initialize(resource, options={})
      @resource = resource
      @entity = options.delete(:entity)
      @key = [options.delete(:key) || @entity.to_s.pluralize].flatten
      @entity_klass = "FreeAgent::#{@entity.to_s.classify}".constantize
    end

    def url
      @resource.url
    end

    def find(id=nil)
      if id
        entity_for_id(id).reload
      else
        super
      end
    end

    def each(&block)
      all.each(&block)
    end

    def all(params={})
      if params.any?
        # very naive Hash-to-params
        resource = @resource['?'+params.map{|k,v|"#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"}.join('&')]
      else
        resource = @resource
      end
      case (response = resource.get).code
      when 200
        entities = Crack::XML.parse(response)
        @key.each do |key|
          entities = entities[key.to_s]
          return [] unless entities
        end
        entities.map do |attributes|
          entity_for_id(attributes['id'], attributes)
        end
      end
    end

    def create(attributes)
      payload = attributes.to_xml(:root => @entity.to_s )
      case (response = @resource.post(payload,
        :content_type => 'application/xml', :accept => 'application/xml')).code
      when 201
        resource_path = URI.parse(response.headers[:location]).path
        @entity_klass.new(@resource.root[resource_path]).reload
      end
    end

    def update(id, attributes)
      entity_for_id(id).update(attributes, headers)
    end

    def destroy(id)
      entity_for_id(id).destroy
    end

    private

    def entity_for_id(id, attributes={})
      @entity_klass.new(@resource["/#{id}"], attributes)
    end

    # Treat the collection as if it's an array otherwise
    def method_missing(method, *args, &block)
      all.send(method, *args, &block)
    end
  end

  class Entity
    def self.has_many(things, options={})
      options.reverse_merge!(:entity => things.to_s.singularize)
      define_method(things) do
        Collection.new(@resource["/#{things}"], options)
      end
    end

    def self.belongs_to(thing, *args)
      define_method(thing) do

      end
      # NOOP right now.
    end

    def self.xml_name
      name.split("::")[1..-1].join("::").underscore
    end

    attr_reader :attributes

    def initialize(resource, attributes = {})
      @resource = resource
      @attributes = attributes.to_mash
    end

    def id
      @attributes.id
    end

    def url
      @resource.url
    end

    def reload
      returning(self) do
        @attributes = Crack::XML.parse(@resource.get)[xml_name].to_mash
      end
    end

    def update(new_attributes)
      attributes.merge!(new_attributes)
      save
    end

    def save
      @resource.put(attributes.to_xml(:root => xml_name),
        :content_type =>'application/xml', :accept => 'application/xml')
    end

    def destroy
      @resource.delete
    end

    private

    def xml_name
      self.class.xml_name
    end

    def method_missing(*args)
      @attributes.send(*args)
    end
  end

  class User < Entity
    has_many :expenses
    has_many :timeslips
  end

  class Project < Entity
    has_many :tasks
    has_many :invoices
    has_many :timeslips
    belongs_to :contact

    def active?
      status == "Active"
    end
  end

  class Invoice < Entity
    has_many :invoice_items
    belongs_to :project
    belongs_to :contact
  end

  class InvoiceItem < Entity
  end

  class Task < Entity
    belongs_to :project
  end

  class Timeslip < Entity
    def initialize(resource, attributes={})
      # need to convert /projects/123/timeslips/456 into /timeslips/456
      tweaked_resource = RestClient::Resource.new(resource.url.gsub(/\/projects\/\d+\//, "/"), resource.options)
      super(tweaked_resource, attributes)
    end

    belongs_to :project
    belongs_to :user
    belongs_to :task
  end

  class Contact < Entity
    has_many :invoices
    has_many :projects
  end

  class Bill < Entity
    belongs_to :contact
    belongs_to :project, :key => :rebilled_to_project_id
  end

  class Expense < Entity
    belongs_to :user
  end

  class Attachment < Entity
  end

  class BankAccount < Entity
  end

  class BankTransaction < Entity
  end
end