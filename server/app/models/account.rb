require 'digest/sha1'
require 'resolv'
require 'net/ldap'

class Account < ActiveRecord::Base
  named_scope :def_scope
    
  validates_presence_of   :login, :email_address, :name
  validates_uniqueness_of :login, :email_address
 
  attr_accessor :password_confirmation
  validates_confirmation_of :password

  def validate
    errors.add("password", "can't be blank") if password_hash.blank?
  end
  
  def self.default_search_attribute
    'login'
  end
 
  def self.authenticate(login, password)
    if password.blank?
      return nil
    end
    account = self.find_by_login(login)
    if account
      authentication_successful = false
      # Try authenticating locally first
      expected_password = encrypted_password(password, account.password_salt)
      if account.password_hash == expected_password
        authentication_successful = true
      # If local authentication failed try LDAP
      else
        authentication_successful = ldap_authenticate(login, password)
      end
      if !authentication_successful
        account = nil
      end
    else # if account
      # The user doesn't currently have a local account.  Try to authenticate
      # them via LDAP, and if that is successful then create a local account
      # with minimal privileges.
      if ldap_authenticate(login, password)
        attrs = ['displayname', 'mail']
        account_params = get_account_params_from_ldap(login, password, attrs)
        if !account_params.nil?
          logger.info "Creating new account, login:#{login}, name:#{account_params['displayname']}, email_address:#{account_params['mail']}"
          account = Account.new(:login => login,
                                :name => account_params['displayname'],
                                :email_address => account_params['mail'],
                                :password_hash => '*',
                                :password_salt => '*')
          if (!account.save)
            # FIXME
            #errors.add
            account.errors.each { |attr,msg| logger.info "Error #{attr}: #{msg}" }
            account = nil
          end
        end
      end
    end # if account
    return account
  end

  def self.get_ldap_connection(login, password)
    # Figure out which server to use to talk to Active DirectoryA
    if LDAP_SERVERS
      res = Resolv::DNS::new()
      ldapservers = res.getresources(LDAP_DNS_NAME,
                                     Resolv::DNS::Resource::IN::SRV)
      ldapsrv = nil
      ldapservers.each do |srv|
        if LDAP_SERVERS.include?(srv.target.to_s)
          ldapsrv = srv.target.to_s
          break
        end
      end
    end
    if LDAP_SERVER
      ldapsrv = LDAP_SERvER
    end

    return nil if ldapsrv.nil?
    logger.info "AD LDAP server is #{ldapsrv}"
    ldap = nil
    if ldapsrv
      if LDAP_EMAIL_SUFFIX
        ldapuser = "#{login}@#{LDAP_EMAIL_SUFFIX}"
      else
        ldapuser = login
      end
      # Note that :simple_tls is SSL, not STARTTLS
      ldap = Net::LDAP.new :host => ldapsrv,
                           :port => 636,
                           :encryption => {:method => :simple_tls},
                           :auth => {:method => :simple,
                                     :username => ldapuser,
                                     :password => password}
    else
      logger.warn "DNS lookup for LDAP server SRV record failed"
    end
    return ldap
  end
  
  def self.ldap_authenticate(login, password)
    authentication_successful = false
    ldap = get_ldap_connection(login, password)
    return nil if ldap.nil?
    if ldap.bind
      authentication_successful = true
    else
      logger.info "LDAP authentication for #{login} failed"
      logger.info ldap.get_operation_result.inspect
    end
    return authentication_successful
  end

  def self.get_account_params_from_ldap(login, password, attrs)
    ldap = get_ldap_connection(login, password)
    return nil if ldap.nil?
    treebase = LDAP_BASE
    filter = Net::LDAP::Filter.eq('sAMAccountName', login)
    results = ldap.search(:base => treebase,
                          :filter => filter,
                          :attributes => attrs)
    # We should only get back one entry
    account_params = nil
    # The docs say we should always get back nil or a result set,
    # but we seem to actually get back false if the search fails.
    # Test for both in case that eventually gets fixed.
    if (!results.nil? && results != false && results.length == 1)
      account_params = {}
      # Extract the first value for each attribute in the result entry
      # into our account_params hash
      results[0].each do |attr_name, attr_values|
        account_params[attr_name.to_s] = attr_values[0].to_s
      end
    else
      logger.info "Search for account params failed"
      logger.info ldap.get_operation_result.inspect
    end
    return account_params
  end

  # 'password' is a virtual attribute
  def password
    @password
  end

  def password=(pwd)
    @password = pwd
    return if pwd.blank?
    create_new_salt
    self.password_hash = Account.encrypted_password(self.password, self.password_salt)
  end
 
  private

  def self.encrypted_password(password, salt)
    string_to_hash = password + "this-is-better" + salt
    Digest::SHA1.hexdigest(string_to_hash)
  end
 
  def create_new_salt
    self.password_salt = self.object_id.to_s + rand.to_s
  end
 
end
