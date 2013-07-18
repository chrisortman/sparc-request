$(document).ready ->

  $(document).on('change', '.clinical_select_data', ->
    $('#visit_form .spinner_wrapper').show()
    visit_name = $('option:selected', this).attr('data-appointment_id')
    setTimeout((->
      $('#visit_form .study_tracker_table').hide()
      $("table[data-appointment_table=#{visit_name}]").css("display", "table")
      $('#visit_form .spinner_wrapper').hide()
    ), 250)
  )

  $(document).on('click', '.clinical_tab_data', ->
    clicked = $(this).parent('li')
    $('#visit_form .spinner_wrapper').show()
    core_name = $(this).attr('id')
    setTimeout((->
      $('.cwf_tabs li.ui-state-active').removeClass('ui-state-active')
      clicked.addClass('ui-state-active')
      $('#visit_form .study_tracker_table tbody tr').hide()
      $("." + core_name).css("display", "table-row")
      $('#visit_form .spinner_wrapper').hide()
    ), 250)
  )
