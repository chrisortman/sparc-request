# Copyright © 2011 MUSC Foundation for Research Development
# All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'directory'

class Identity < ActiveRecord::Base

  include RemotelyNotifiable

  audited

  after_create :send_admin_mail

  #Version.primary_key = 'id'
  #has_paper_trail

  #### DEVISE SETUP ####
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :omniauthable

  email_regexp = /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/
  password_length = 6..128

  validates_format_of     :email, :with  => email_regexp, :allow_blank => true, :if => :email_changed?

  validates_presence_of     :password, :if => :password_required?
  validates_confirmation_of :password, :if => :password_required?
  validates_length_of       :password, :within => password_length, :allow_blank => true

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :company, :reason, :approved
  # attr_accessible :title, :body
  #### END DEVISE SETUP ####

  has_many :approvals, :dependent => :destroy
  has_many :project_roles, :dependent => :destroy
  has_many :protocols, :through => :project_roles
  has_many :projects, :through => :project_roles, :source => :protocol, :conditions => "protocols.type = 'Project'"
  has_many :studies, :through => :project_roles, :source => :protocol, :conditions => "protocols.type = 'Study'"
  has_many :super_users, :dependent => :destroy
  has_many :catalog_managers, :dependent => :destroy
  has_many :clinical_providers, :dependent => :destroy
  has_many :protocol_service_requests, :through => :protocols, :source => :service_requests
  has_many :requested_service_requests, :class_name => 'ServiceRequest', :foreign_key => 'service_requester_id'
  has_many :catalog_manager_rights, :class_name => 'CatalogManager'
  has_many :service_providers, :dependent => :destroy
  has_many :notifications, :foreign_key => 'originator_id'
  has_many :sent_messages, :class_name => 'Message', :foreign_key => 'from'
  has_many :received_messages, :class_name => 'Message', :foreign_key => 'to'
  has_many :user_notifications, :dependent => :destroy
  has_many :received_toast_messages, :class_name => 'ToastMessage', :foreign_key => 'to', :dependent => :destroy
  has_many :sent_toast_messages, :class_name => 'ToastMessage', :foreign_key => 'from', :dependent => :destroy
  has_many :notes, :dependent => :destroy

  # TODO: Identity doesn't really have many sub service requests; an
  # identity is the owner of many sub service requests.  We need a
  # better name here.
  # has_many :sub_service_requests, :foreign_key => 'owner_id'

  attr_accessible :ldap_uid
  attr_accessible :email
  attr_accessible :last_name
  attr_accessible :first_name
  attr_accessible :institution
  attr_accessible :college
  attr_accessible :department
  attr_accessible :era_commons_name
  attr_accessible :credentials
  attr_accessible :credentials_other
  attr_accessible :phone
  attr_accessible :catalog_overlord
  attr_accessible :subspecialty

  cattr_accessor :current_user

  validates_presence_of :last_name
  validates_presence_of :first_name
  validates :ldap_uid, uniqueness: {case_sensitive: false}, presence: true


  ###############################################################################
  ############################## DEVISE OVERRIDES ###############################
  ###############################################################################

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def email_required?
    false
  end

  ###############################################################################
  ############################## HELPER METHODS #################################
  ###############################################################################

  # Returns this user's first and last name humanized.
  def full_name
    "#{first_name.try(:humanize)} #{last_name.try(:humanize)}".lstrip.rstrip
  end

 # Returns this user's first and last name humanized, with their email.
  def display_name
    "#{first_name.try(:humanize)} #{last_name.try(:humanize)} (#{email})".lstrip.rstrip
  end

  # Return the netid (ldap_uid without the @musc.edu)
  def netid
    if USE_LDAP then
      return ldap_uid.sub(/@#{Directory::DOMAIN}/, '')
    else
      return ldap_uid
    end
  end

  ###############################################################################
  ############################ ATTRIBUTE METHODS ################################
  ###############################################################################

  # Returns true if the user is a catalog overlord.  Should only be true for three uids:
  # lmf5, anc63, mas244
  def is_overlord?
    @is_overlord ||= self.catalog_overlord?
  end

  def is_super_user?
    @is_super_user ||= self.super_users.count > 0
  end

  def is_service_provider? ssr
   is_provider = false
   orgs =[]
   orgs << ssr.organization << ssr.organization.parents
   orgs.flatten!
   orgs.each do |org|
     provider_ids = org.service_providers_lookup.map{|x| x.identity_id}
     if provider_ids.include?(self.id)
     is_provider = true
     end
   end

  is_provider

  end

  ###############################################################################
  ############################# SEARCH METHODS ##################################
  ###############################################################################

  def self.search(term)
    return Directory.search(term)
  end

  ###############################################################################
  ########################### PERMISSION METHODS ################################
  ###############################################################################

  # DEVISE specific methods
  def self.find_for_shibboleth_oauth(auth, signed_in_resource=nil)
    identity = Identity.where(:ldap_uid => auth.uid).first

    unless identity
      identity = Identity.create :ldap_uid => auth.uid, :first_name => auth.info.first_name, :last_name => auth.info.last_name, :email => auth.info.email, :password => Devise.friendly_token[0,20], :approved => true
    end
    identity
  end

  def active_for_authentication?
    super && approved?
  end

  def inactive_message
    if !approved?
      :not_approved
    else
      super # Use whatever other message
    end
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(ldap_uid) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

  def self.send_reset_password_instructions(attributes={})
    recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
    if !recoverable.approved?
      recoverable.errors[:base] << I18n.t("devise.failure.not_approved")
    elsif recoverable.persisted?
      recoverable.send_reset_password_instructions
    end
    recoverable
  end

  def send_admin_mail
    unless self.approved
      Notifier.new_identity_waiting_for_approval(self).deliver
    end
  end

  # As per Lane, a service request's status is no longer a factor for editing.
  # Only users with request or approve rights can edit.
  def can_edit_service_request? sr
    can_edit = false

    if (sr.service_requester_id == self.id or sr.service_requester_id.nil?) && sr.is_editable?
      can_edit = true
    elsif sr.is_editable? && has_correct_project_role?(sr)
      can_edit = true
    end

    can_edit
  end

  # If a user has request or approve rights AND the request is editable, then the user can edit.
  def can_edit_sub_service_request? ssr
    if ssr.can_be_edited? && has_correct_project_role?(ssr)
      return true
    end

    return false
  end

  def has_correct_project_role? request
    self.project_roles.each do |pr|
      if (pr.protocol_id == requests_protocol_id(request)) && ['approve', 'request'].include?(pr.project_rights)
        return true
      end
    end

    return false
  end

  def requests_protocol_id request
    if request.class == ServiceRequest
      id = request.try(:protocol).try(:id)
    else
      id = request.service_request.try(:protocol).try(:id)
    end

    id
  end

  # Determines whether this identity can edit a given organization's information in CatalogManager.
  # Returns true if this identity's catalog_manager_organizations includes the given organization.
  def can_edit_entity? organization, deep_search=false
    cm_org_ids = self.catalog_managers.map(&:organization_id)
    if deep_search
      org_ids = [organization.id].concat(organization.parents(true))
      org_ids -  cm_org_ids != org_ids
    else
      cm_org_ids.include?(organization.id)
    end
  end

  # Used in clinical fulfillment to determine whether the user can edit a particular core.
  def can_edit_core?(organization_id)
    organizations = (clinical_provider_organizations + super_user_organizations).flatten.uniq

    organizations.map(&:id).include? organization_id
  end

  # Determines whether the user has permission to edit historical data for a given organization.
  # Returns true if the edit_historic_data flag is set to true on the relevant catalog_manager relationship.
  def can_edit_historical_data_for? organization
    if self.catalog_manager_organizations.include?(organization)
      if self.catalog_managers.find_by_organization_id(organization.id)
        if self.catalog_managers.find_by_organization_id(organization.id).edit_historic_data
          return true
        else
          return self.can_edit_historical_data_for? organization.parent
        end
      else
        return self.can_edit_historical_data_for? organization.parent
      end
    end

    false
  end

  # Determines whether the user has permission to access the admin portal for a given organization.
  # Returns true if the user is a super user or service provider for the given organization or
  # any of its parents. (Recursively calls itself to climb the tree of parents)
  def can_edit_fulfillment? organization
    arr = []
    arr << self.super_users.map(&:organization_id)
    arr << self.service_providers.map(&:organization_id)
    arr = arr.flatten.uniq
    if organization.type == 'Institution'
      arr.include? organization.id
    else
      can_edit_fulfillment? organization.parent or arr.include? organization.id
    end
  end

  ###############################################################################
  ########################### COLLECTION METHODS ################################
  ###############################################################################

  def catalog_manager_organizations
    organizations = Array.new

    catalog_managers.map(&:organization).each do |organization|
      organizations.push [organization, organization.all_children]
    end

    organizations.flatten
  end

  def service_provider_organizations
    organizations = Array.new

    service_providers.map(&:organization).each do |organization|
      organizations.push [organization, organization.all_children]
    end

    organizations.flatten
  end

  def super_user_organizations
    organizations = Array.new

    super_users.map(&:organization).each do |organization|
      organizations.push [organization, organization.all_children]
    end

    organizations.flatten
  end

  def clinical_provider_organizations
    organizations = Array.new

    clinical_providers.map(&:organization).each do |organization|
      organizations.push [organization, organization.all_children]
    end

    organizations.flatten
  end

  def admin_organizations
    (super_user_organizations + service_provider_organizations).flatten.uniq
  end

  def clinical_provider_rights?
    #TODO should look at all tagged with CTRC
    org = Organization.tagged_with("ctrc").first
    if !self.clinical_providers.empty? or super_user_organizations.include?(org)
      return true
    else
      return false
    end
  end

  def clinical_provider_for_ctrc?
    #TODO should look at all tagged with CTRC
    org = Organization.tagged_with("ctrc").first
    return false if org.nil? #if no orgs have nexus tag
    self.clinical_providers.each do |provider|
      if provider.organization_id == org.id
        return true
      end
    end

    return false
  end

  # Collects all sub service requests under this identity's admin_organizations and sorts that
  # list by the status of the sub service requests.
  # Used to populate the table (as selectable by the dropdown) in the admin index.
  def admin_service_requests_by_status org_id=nil, admin_orgs=nil
    ##Default to all ssrs, if we get an org_id, only get that organization's ssrs
    ssrs = []
    if org_id
      ssrs = Organization.find(org_id).sub_service_requests
    elsif admin_orgs && !admin_orgs.empty?
      ssrs = SubServiceRequest.where("sub_service_requests.organization_id in (#{admin_orgs.map(&:id).join(", ")})").includes(:owner, :line_items => :service, :service_request => [:service_requester, :protocol => {:project_roles => :identity}])
    else
      self.admin_organizations.each do |org|
        ssrs << SubServiceRequest.where(:organization_id => org.id).includes(:line_items => :service, :service_request => :protocol).to_a
      end
      ssrs.flatten!
    end

    hash = {}

    ssrs.each do |ssr|
      unless ssr.status.blank? or ssr.status == 'first_draft'
        if ssr.service_request
          if ssr.service_request.protocol
            ssr_status = ssr.status.to_s.gsub(/\s/, "_").gsub(/[^-\w]/, "").downcase
            hash[ssr_status] = [] unless hash[ssr_status]
            hash[ssr_status] << ssr
          end
        end
      end
    end

    hash
  end

  ###############################################################################
  ########################## NOTIFICATION METHODS ###############################
  ###############################################################################

  # Collects all notifications for this identity based on their user notifications (as notifications
  # do not belong to individual identities).
  # Returns an array of Notifications.
  def all_notifications
    ids = self.user_notifications.map {|x| x.notification_id}
    all_notifications = Notification.where(:id => ids)

    all_notifications
  end

  # Returns the count of unread notifications for this identity, based on their user_notifications
  # (where the :read flag is set).
  def unread_notification_count user
    notification_count = 0
    notifications = self.all_notifications

    notifications.each do |notification|
      notification_count += 1 unless notification.user_notifications_for_current_user(user).order('created_at DESC').first.read
    end

    notification_count
  end
end
