class ServiceProfile < ActiveRecord::Base
  named_scope :def_scope
  acts_as_authorizable
  acts_as_reportable
  acts_as_commentable

  belongs_to :node_group

  # for some reason, when using accepts_nested_attributes_for, cannot validate presence
  #validates_presence_of :service_id
  #validates_uniqueness_of :service_id
  #validates_inclusion_of :external, :in => [true, false]
  #validates_inclusion_of :pciscope, :in => [true, false]

  def validate
    validates_contact
  end

  def validates_contact
    if (contact.blank? || contact.nil?)
      return true
    else
      flag = []
      users = contact.split(',')
      users.each do |user|
        if user =~ /@/
          flag << user unless user =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
        elsif SSO_AUTH_SERVER && SSO_PROXY_SERVER
          user.strip!
          uri = URI.parse("https://#{SSO_AUTH_SERVER}/users.xml?login=#{user}")
          http = Net::HTTP::Proxy(SSO_PROXY_SERVER,8080).new(uri.host,uri.port)
          http.use_ssl = true
          sso_xmldata = http.get(uri.request_uri).body
          sso_xmldoc = Hpricot::XML(sso_xmldata)
          if (sso_xmldoc/:kind).first
            kind = (sso_xmldoc/:kind).first.innerHTML
            unless kind == "employee"|| kind == "contractor"
              flag << user
            end 
          else
            flag << user
          end # if (sso_xmldoc/:kind).first
        else
          flag << user
        end # if user =~ /@/
      end 
    end 
    if (flag.nil? || flag.empty?)
      return true 
    else
      errors.add(:contact, "Unknown user #{flag.join(' ')} or invalid format specified in contact field.\n(Example: jsmith,mjones,kgates,jsmith@example.com)\n")
      return false
    end 
  end 

  def self.default_search_attribute
    'dev_url'
  end
end
