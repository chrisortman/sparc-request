$("#modal_place").html("<%= escape_javascript(render(:partial =>'portal/arms/add_arm_form', locals: {protocol: @protocol, arm: @arm, current_page: @current_page, services: @services, schedule_tab: @schedule_tab, sub_service_request: @sub_service_request, service_request: @service_request})) %>");
$("#modal_place").modal 'show'
$(".selectpicker").selectpicker()