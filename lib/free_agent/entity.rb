module FreeAgent
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
      @attributes = Hashie::Mash.new(attributes)
    end

    def id
      @attributes.id
    end

    def url
      @resource.url
    end

    def reload
      returning(self) do
        @attributes = Hashie::Mash.new(Crack::XML.parse(@resource.get)[xml_name])
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
end