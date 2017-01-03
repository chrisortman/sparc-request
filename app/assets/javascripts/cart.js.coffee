
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
$(document).ready ->
  $(document).on 'click', '.cart-toggle .btn', ->
    tab = $(this).data('tab')
    if !$(this).hasClass('active')
      $(this).addClass('active' )
      $(this).siblings('.btn').removeClass('active')
      $('.ssr-tab').addClass('hidden')
      if tab == 'active'
        $('.active-ssrs').removeClass('hidden')
      else if tab == 'complete'
        $('.complete-ssrs').removeClass('hidden')
    return false

  $(document).on 'click', '.add-service', ->
    id = $(this).data('id')
    srid = $(this).data('srid')
    has_protocol = parseInt($('#has_protocol').val())
    li_count = parseInt($('#line_item_count').val())

    if has_protocol == 0 && li_count == 0
      $('#modal_place').html($('#new-request-modal').html())
      $('#modal_place').modal('show')
      $('#modal_place .yes-button').data('srid', srid)
      $('#modal_place .yes-button').data('service-id', id)
      $('#modal_place .yes-button').on 'click', (e) ->
        addService(srid, id)
    else
      addService(srid, id)

  $(document).on 'click', '.remove-service', ->
    id = $(this).data('id')
    srid = $(this).data('srid')
    editing_ssr = $(this).data('editing-ssr')
    li_count = parseInt($('#line_item_count').val())
    has_fulfillments = $(this).data('has-fulfillments')
    request_submitted = $(this).data('request-submitted')
    spinner = $('<span class="spinner"><img src="/assets/catalog_manager/spinner_small.gif"/></span>')

    if has_fulfillments == 1
      $('#modal_place').html($('#has-fulfillments-modal').html())
      $('#modal_place').modal('show')
    else if request_submitted == 1
      button = $(this)
      $('#modal_place').html($('#request-submitted-modal').html())
      $('#modal_place').modal('show')

      $('#modal_place .yes-button').on 'click', (e) ->
        button.replaceWith(spinner)
        removeService(srid, id, false, spinner)
    else
      if editing_ssr == 1 && li_count == 1 # Redirect to the Dashboard if the user deletes the last Service on an SSR
        $('#modal_place').html($('#remove-request-modal').html())
        $('#modal_place').modal('show')

        $('#modal_place .yes-button').on 'click', (e) ->
          button.replaceWith(spinner)
          removeService(srid, id, true, spinner)
      else if li_count == 1 && window.location.pathname.indexOf('catalog') == -1 # Do not allow the user to remove the last service except in the catalog
        $('#modal_place').html($('#line-item-required-modal').html())
        $('#modal_place').modal('show')
      else
        $(this).replaceWith(spinner)
        removeService(srid, id, false, spinner)

addService = (srid, id) ->
  $.ajax
    type: 'POST'
    url: "/service_requests/#{srid}/add_service/#{id}"

removeService = (srid, id, move_on, spinner) ->
  $.ajax
    type: 'POST'
    url: "/service_requests/#{srid}/remove_service/#{id}"
    success: (data, textStatus, jqXHR) ->
      if move_on
        window.location = '/dashboard'
      else
        spinner.hide()