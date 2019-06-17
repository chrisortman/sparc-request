# Copyright © 2011-2019 MUSC Foundation for Research Development
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

<% if @new_request %>
ConfirmSwal.fire(
  type: 'question'
  title: I18n.t('proper.catalog.new_request.header')
  text: I18n.t('proper.catalog.new_request.warning')
  confirmButtonText: I18n.t('proper.catalog.new_request.yes_button')
  cancelButtonText: I18n.t('proper.catalog.new_request.no_button')
  customClass:
    confirmButton: 'btn-success'
    cancelButton: 'btn-danger'

).then (result) =>
  if result.value
    $.ajax
      type: 'post'
      dataType: 'script'
      url: '/service_request/add_service'
      data:
        service_id: "<%= params[:service_id] %>"
        confirmed: "true"
  else
    window.location = "<%= dashboard_root_path %>"
<% elsif @duplicate_service %>
AlertSwal.fire(
  type: 'error'
  title: I18n.t('proper.cart.duplicate_service.header')
  text: I18n.t('proper.cart.duplicate_service.warning')
)
<% else %>
$('#stepsNav').replaceWith("<%= j render 'service_requests/navigation/steps' %>")
$('#cart').replaceWith("<%= j render 'service_requests/cart/cart', service_request: @service_request %>")

url = new URL(window.location.href)
if !url.searchParams.get('srid')
  url.searchParams.append('srid', "<%= @service_request.id %>")
  window.history.pushState({}, null, url.href)
  $('input[name=srid]').val("<%= @service_request.id %>")
  $('#loginLink').attr('href', "<%= new_identity_session_path(srid: @service_request.id) %>")
<% end %>
