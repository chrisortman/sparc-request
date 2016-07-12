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

#= require cart

$(document).ready ->
  ### Related to locked service requests ###
  $('#ctrc-dialog').dialog
    autoOpen: false
    modal: true
    width: 375
    height: 200
    buttons: [{
      text: 'Ok'
      click: ->
        $(this).dialog('close')
    }]

  $(document).on 'click', '.locked a', ->
    if $(this).text() == 'Research Nexus **LOCKED**'
      $('#ctrc-dialog').dialog('open')

  ### Organization Accordion Logic ###
  $('#institution-accordion').accordion
    heightStyle: 'content'
    collapsible: true

  $('.provider-accordion').accordion
    heightStyle: 'content'
    collapsible: true
    active: false

  $(document).on 'click', '.institution-header, .provider-header', ->
    $('#processing-request').removeClass('hidden')
    id    = $(this).data('id')
    $.ajax
      type: 'POST'
      url: "/catalogs/#{id}/update_description"
      success: ->
        $('#processing-request').addClass('hidden')

  $(document).on 'click', '.program-link', ->
    $('#processing-request').removeClass('hidden')
    id    = $(this).data('id')
    data  = process_ssr_found : $(this).data('process-ssr-found') 
    $.ajax
      type: 'POST'
      data: data
      url: "/catalogs/#{id}/update_description"
      success: ->
        $('#processing-request').addClass('hidden')

  $(document).on 'click', '.core-header', ->
    $('.service-description').addClass('hidden')

  $(document).on 'click', '.service-view .title .name a', ->
    id = $(this).data('id')
    description = $(".service-description-#{id}")

    if description.hasClass('hidden')
      $('.service-description').addClass('hidden')
      description.removeClass('hidden')
    else
      description.addClass('hidden')

  ### Search Logic ###
  autoComplete = $('#service-query').autocomplete
    source: '/search/services'
    minLength: 2
    search: (event, ui) ->
      $("#service-query").after('<img src="/assets/spinner.gif" class="catalog-search-spinner" />')
    open: (event, ui) ->
      $('.catalog-search-spinner').remove()
      $('.service-name').qtip
        content: { text: false}
        position:
          corner:
            target: "rightMiddle"
            tooltip: "leftMiddle"

          adjust: screen: true

        show:
          delay: 0
          when: "mouseover"
          solo: true

        hide:
          delay: 0
          when: "mouseout"
          solo: true
        
        style:
          tip: true
          border:
            width: 0
            radius: 4

          name: "light"
          width: 250

    close: (event, ui) ->
      $('.catalog-search-spinner').remove()
      $('.catalog-search-clear-icon').remove()

  .data("uiAutocomplete")._renderItem = (ul, item) ->    
    label = item.label
    unless item.label is 'No Results'
      label = "#{item.parents}<br>
              <span class='service-name' title='#{item.description}'>
              #{item.label}<br> 
              CPT Code: #{item.cpt_code}<br> 
              Abbreviation: #{item.abbreviation}</span><br>
              <button id='service-#{item.value}' 
              sr_id='#{item.sr_id}' 
              from_portal='#{item.from_portal}' 
              first_service='#{item.first_service}' 
              style='font-size: 11px;' 
              class='add_service'>Add to Cart</button>
              <span class='service-description'>#{item.description}</span>"

    $("<li class='search_result'></li>")
    .data("ui-autocomplete-item", item)
    .append(label)
    .appendTo(ul)

  $(document).on 'click', '.submit-request-button', ->
    signed_in = $(this).data('signed-in')

    if $('#line_item_count').val() <= 0
      $('#modal_place').html($('#submit-error-modal').html())
      $('#modal_place').modal('show')
      $('.modal #submit-error-modal').removeClass('hidden')
      return false
    else if !signed_in
      $('#sign_in').dialog
        modal: true
      return false
