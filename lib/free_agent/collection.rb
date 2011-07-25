require "active_support/inflections"

module FreeAgent
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
          entities = [key, :objects].map { |k| entities[k.to_s] }.compact.first
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
end