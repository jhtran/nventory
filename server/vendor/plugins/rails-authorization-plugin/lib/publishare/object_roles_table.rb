require File.dirname(__FILE__) + '/exceptions'
require File.dirname(__FILE__) + '/identity'

module Authorization
  module ObjectRolesTable

    module UserExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end

      module ClassMethods
        def acts_as_authorized_user(roles_relationship_opts = {})
          has_many :roles_users, roles_relationship_opts.merge(:dependent => :delete_all)
          has_many :roles, :through => :roles_users
          include Authorization::ObjectRolesTable::UserExtensions::InstanceMethods
          include Authorization::Identity::UserExtensions::InstanceMethods   # Provides all kinds of dynamic sugar via method_missing
        end
      end

      module InstanceMethods
        # If roles aren't explicitly defined in user class then check roles table
        def has_role?(role_name, authorizable_obj=nil)
          if role_name.class == Hash
            return role_name.all? { |k,v| check_role k, v }
          else
            return check_role role_name, authorizable_obj
          end
        end

        def has_role(role_name, authorizable_obj=nil, attrs=nil)
          if role_name.class == Hash
            role_name.each { |k,v| assign_role k, v }
          else
            assign_role role_name, authorizable_obj, attrs
          end
        end

        def has_no_role(role_name, authorizable_obj=nil)
          role = get_role( role_name, authorizable_obj )
          self.roles.delete( role ) if role
          delete_role_if_empty( role )
        end

        def has_roles_for?( authorizable_obj )
          if authorizable_obj.is_a? Class
            (!self.roles.detect { |role| role.authorizable_type == authorizable_obj.to_s && role.authorizable_id.nil? }.nil? ||
             !self.roles.detect { |role| role.authorizable_type.nil? && role.authorizable_id.nil? }.nil?)
          elsif authorizable_obj
            (!self.roles.detect { |role| role.authorizable_type == authorizable_obj.class.to_s && role.authorizable == authorizable_obj }.nil? ||
             !self.roles.detect { |role| role.authorizable_type == authorizable_obj.class.to_s && role.authorizable_id.nil? }.nil? ||
             !self.roles.detect { |role| role.authorizable_type.nil? && role.authorizable_id.nil? }.nil?)
          else
            !self.roles.detect { |role| role.authorizable_type.nil? && role.authorizable_id.nil? }.nil?
          end
        end
        alias :has_role_for? :has_roles_for?

        def roles_for( authorizable_obj )
          if authorizable_obj.is_a? Class
            self.roles.find(:all, :conditions => { :authorizable_type => authorizable_obj.to_s})
          elsif authorizable_obj
            self.roles.find(:all, :conditions => {
                              :authorizable_type => authorizable_obj.class.to_s,
                              :authorizable_id => authorizable_obj.id })
          else
            self.roles.select { |role| role.authorizable.nil? }
          end
        end

        def has_no_roles_for(authorizable_obj = nil)
          old_roles = roles_for(authorizable_obj).dup
          self.roles.delete(old_roles)
          old_roles.each { |role| delete_role_if_empty( role ) }
        end

        def has_no_roles
          old_roles = self.roles.dup
          self.roles.clear
          old_roles.each { |role| delete_role_if_empty( role ) }
        end

        def authorizables_for( authorizable_class )
          unless authorizable_class.is_a? Class
            raise CannotGetAuthorizables, "Invalid argument: '#{authorizable_class}'. You must provide a class here."
          end
          begin
            authorizable_class.find(
              self.roles.find_all_by_authorizable_type(authorizable_class.to_s).map(&:authorizable_id).uniq
            )
          rescue ActiveRecord::RecordNotFound
            []
          end
        end

        private

        def get_role( role_name, authorizable_obj )
          role_name = role_name.to_s if role_name.is_a? Symbol
          if authorizable_obj.nil?
            Role.find(
              :first,
              :conditions => [
                'name = ? and authorizable_type IS NULL and authorizable_id IS NULL',
                role_name
              ]
            )
          elsif authorizable_obj.is_a? Class
            Role.find(
              :first,
              :conditions => [
                'name = ? and authorizable_type = ? and authorizable_id IS NULL',
                role_name,
                authorizable_obj.to_s
              ]
            )
          else
            Role.find(
              :first,
              :conditions => [
                'name = ? and authorizable_type = ? and authorizable_id = ?',
                role_name,
                authorizable_obj.class.to_s,
                authorizable_obj.id
              ]
            )
          end
        end

        def assign_role(role_name, scope=nil, attrs=nil)
          role_name = role_name.to_s if role_name.is_a? Symbol
          role = get_role(role_name, scope)
          if role.nil?
            if scope.nil?
              role = Role.create( :name => role_name )
            elsif scope.is_a? Class
              role = Role.create( :name => role_name, :authorizable_type => scope.to_s )
            else
              role = Role.create( :name => role_name, :authorizable => scope )
            end
          end
          if role and !self.roles.exists?( role )
            self.roles << role 
            if attrs
logger.info "\n\n\n\n\n\n ATTRIBUTES #{attrs} \n\n\n\n"
              myrole = RolesUser.find_by_role_id_and_account_group_id(role.id,self.id)
logger.info "\n\n\n\n\n\n myrole #{myrole.id} \n\n\n\n"
              myrole.update_attributes({:attrs => attrs})
            end # if attrs
          end
        end

        def check_role(role_name, scope=nil)
          return true if self.roles.member? get_role(role_name,nil)

          if (!scope.nil?)
            return true if self.roles.include?(get_role(role_name, scope))
            return true if !scope.is_a?(Class) && self.roles.include?(get_role(role_name, scope.class))
          end

          false
        end

        def delete_role_if_empty( role )
          role.destroy if role && role.users.count == 0
        end

      end
    end

    module ModelExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end

      module ClassMethods
        def acts_as_authorizable
          has_many :accepted_roles, :as => :authorizable, :class_name => 'Role'

          has_many :users,
            :finder_sql => '
              SELECT
                DISTINCT accounts.*
              FROM
                accounts
                INNER JOIN roles_users
                  ON user_id = accounts.id
                INNER JOIN roles
                  ON roles.id = role_id
              WHERE
                authorizable_type = \'#{self.class.to_s}\'
                AND authorizable_id = #{id}',
            :counter_sql => '
              SELECT
                COUNT(DISTINCT accounts.id)
              FROM
                accounts
                INNER JOIN roles_users
                  ON user_id = accounts.id
                INNER JOIN roles
                  ON roles.id = role_id
              WHERE
                authorizable_type = \'#{self.class.to_s}\'
                AND authorizable_id = #{id}',
            :readonly => true

          before_destroy :remove_user_roles

          def allowed_roles
            Role.find(:all, :include => {:roles_users => {},:users =>{}}, :conditions => ["(authorizable_type = ? and authorizable_id is null) or (authorizable_type is null and authorizable_id is null)", self.to_s])
          end

          def accepts_role?( role_name, user )
            user.has_role? role_name, self
          end

          def accepts_role( role_name, user, attrs=nil )
            user.has_role role_name, self, attrs
          end

          def accepts_no_role( role_name, user )
            user.has_no_role role_name, self
          end

          def accepts_roles_by?( user )
            user.has_roles_for? self
          end
          alias :accepts_role_by? :accepts_roles_by?

          def accepted_roles_by( user )
            user.roles_for self
          end

          def authorizables_by( user )
            user.authorizables_for self
          end

          include Authorization::ObjectRolesTable::ModelExtensions::InstanceMethods
          include Authorization::Identity::ModelExtensions::InstanceMethods   # Provides all kinds of dynamic sugar via method_missing
        end
      end

      module InstanceMethods
        def allowed_roles
          Role.find(:all, :include => {:roles_users => {},:users =>{}}, :conditions => ["(authorizable_type = ? and authorizable_id = ?) or (authorizable_type is null and authorizable_id is null) or (authorizable_type = ? and authorizable_id is null)", self.class.to_s, self.id, self.class.to_s])
        end

        # If roles aren't overriden in model then check roles table
        def accepts_role?( role_name, user )
          user.has_role? role_name, self
        end

        def accepts_role( role_name, user, attrs=nil )
          user.has_role role_name, self, attrs
        end

        def accepts_no_role( role_name, user )
          user.has_no_role role_name, self
        end

        def accepts_roles_by?( user )
          user.has_roles_for? self
        end
        alias :accepts_role_by? :accepts_roles_by?

        def accepted_roles_by( user )
          user.roles_for self
        end

        private

        def remove_user_roles
          self.accepted_roles.each do |role|
            role.roles_users.delete_all
            role.destroy
          end
        end

      end
    end

  end
end

