class Portal::VisitGroupsController < Portal::BaseController
  respond_to :json, :html
  before_action :find_visit_group, only: [:update, :destroy]

  def new
    @service_request = ServiceRequest.find(params[:service_request_id])
    @sub_service_request = SubServiceRequest.find(params[:sub_service_request_id])
    @current_page = params[:current_page] # the current page of the study schedule
    @protocol = Protocol.find(params[:protocol_id])
    @visit_group = VisitGroup.new()
    @schedule_tab = params[:schedule_tab]
    @arm = params[:arm_id].present? ? Arm.find(params[:arm_id]) : @protocol.arms.first
    @study_tracker = params[:study_tracker] == "true"
  end

  def create
    @service_request = ServiceRequest.find(params[:service_request_id])
    @sub_service_request = SubServiceRequest.find(params[:sub_service_request_id])
    @subsidy = @sub_service_request.subsidy
    percent = @subsidy.try(:percent_subsidy).try(:*, 100)
    @arm =  Arm.find(params[:visit_group][:arm_id])
    @current_page = params[:current_page]
    @schedule_tab = params[:schedule_tab]
    @study_tracker = params[:study_tracker] == "true"

    if @arm.add_visit(params[:visit_group][:position], params[:visit_group][:day], params[:visit_group][:window_before], params[:visit_group][:window_after], params[:visit_group][:name], 'true')
      @subsidy.try(:sub_service_request).try(:reload)
      @subsidy.try(:fix_pi_contribution, percent)
      @candidate_per_patient_per_visit = @sub_service_request.candidate_services.reject {|x| x.one_time_fee}
      @arm.increment!(:minimum_visit_count)
      @service_request.relevant_service_providers_and_super_users.each do |identity|
        create_visit_change_toast(identity, @sub_service_request) unless identity == @user
      end
      flash[:success] = "Visit Created!"
    else
      @errors = @arm.errors
    end
  end

  def navigate
    # Used in study schedule management for navigating to a visit group, given an index of them by arm.
    @protocol = Protocol.find(params[:protocol_id])
    @service_request = ServiceRequest.find(params[:service_request_id])
    @sub_service_request = SubServiceRequest.find(params[:sub_service_request_id])
    @intended_action = params[:intended_action]
    if params[:visit_group_id]
      @visit_group = VisitGroup.find(params[:visit_group_id])
      @arm = @visit_group.arm
    else
      @arm = params[:arm_id].present? ? Arm.find(params[:arm_id]) : @protocol.arms.first
      @visit_group = @arm.visit_groups.first
    end
  end

  def update
    @service_request = ServiceRequest.find(params[:service_request_id])
    @sub_service_request = SubServiceRequest.find(params[:sub_service_request_id])
    @arm = @visit_group.arm
    if @visit_group.update_attributes(params[:visit_group])
      flash[:success] = "Visit Updated"
    else
      @errors = @visit_group.errors
    end
  end

  def destroy
    @service_request = ServiceRequest.find(params[:service_request_id])
    @sub_service_request = SubServiceRequest.find(params[:sub_service_request_id])
    @current_page = params[:page].to_i == 0 ? 1 : params[:page].to_i # can't be zero
    @schedule_tab = params[:schedule_tab]
    @study_tracker = params[:study_tracker] == "true"
    @arm = @visit_group.arm
    if @arm.remove_visit(@visit_group.position)
      @subsidy = @sub_service_request.subsidy
      percent = @subsidy.try(:percent_subsidy).try(:*, 100)
      @subsidy.try(:sub_service_request).try(:reload)
      @subsidy.try(:fix_pi_contribution, percent)
      @candidate_per_patient_per_visit = @sub_service_request.candidate_services.reject {|x| x.one_time_fee}
      @arm.decrement!(:minimum_visit_count)
      @service_request.relevant_service_providers_and_super_users.each do |identity|
        create_visit_change_toast(identity, @sub_service_request) unless identity == @user
      end
      flash.now[:alert] = "Visit Deleted"
    else
      @errors = @arm.errors
    end
  end

  private

  def find_visit_group
    @visit_group = VisitGroup.find(params[:id])
  end

  def create_visit_change_toast identity, sub_service_request
    ToastMessage.create(
      :to => identity.id,
      :from => current_identity.id,
      :sending_class => 'SubServiceRequest',
      :sending_class_id => sub_service_request.id,
      :message => "The visit count on this service request has been changed"
    )
  end
end