module CostAnalysis

  class ServiceRequest
    def initialize(service_request, styles)
      @service_request = service_request
      @styles = styles
    end

    def update(sheet) #workbook

      row_header_style = @styles.row_header_style
      table_header_style = @styles.table_header_style
      default = @styles.default
      printed_visit_headers = false
      @service_request.arms.each do |arm|

        visit_per_patient_totals = []
        visit_all_patients_totals = []
        # Watch out side effect. coincidental when this
        # gets used later that it will have visit headers in the right spot
        headers = []

        pppv_line_item_visits(arm).each do |ssr, livs|

          service_per_patient_subtotal = 0
          service_per_study_subtotal = 0

          headers = [
            display_org_name_text(livs[0].line_item.service.organization_hierarchy, ssr, true),
            nil,
            "Current",
            "Your\nPrice",
            "Subjects"
          ] + arm.visit_groups.map { |vg| "#{vg.name}\nDay#{vg.day}" } + [
            "Per Patient",
            "Per Study"
          ]

          header_styles = [@styles.org_hierarchy_header, @styles.org_hierarchy_header] + Array.new(headers.size-2, @styles.visit_header)

          # Dont want to show any of the visit
          # column headers
          if printed_visit_headers
            new_headers = Array.new(headers.size,nil)
            new_headers[0] = headers[0]
            headers = new_headers

            header_styles = Array.new(headers.size, @styles.org_hierarchy_header)
          end

          #Header row that lists the program > core > service tree
          sheet.add_row(
            headers,
            :style => header_styles
          )
          printed_visit_headers = true

          #This is each line
          livs.each do |liv|

            first_in_row = liv.line_item.service.display_service_name
            unless liv.line_item.service.is_available
              first_in_row += inactive_tag
            end

            row = [
              first_in_row,
              display_unit_type(liv),
              display_service_rate(liv.line_item),
              Service.cents_to_dollars(liv.line_item.applicable_rate),
              liv.subject_count
            ]

            # visits is visit 1, visit 2, visit N...
            visits = eager_loaded_visits(liv)

            line_per_patient_total = 0
            line_per_study_total = 0
            # building the columns for each visit on the line
            row += visits.to_enum.with_index(0).map do |v, visit_index|

              qty = v.research_billing_qty + v.insurance_billing_qty
              
              per_patient = qty * Service.cents_to_dollars(liv.line_item.applicable_rate)

              #add to the per patient total for this line
              #TODO: Which cost to use here? I think applicable rate?
              line_per_patient_total += per_patient
              #add to the per study total for this line
              line_per_study_total += (liv.subject_count * Service.cents_to_dollars(liv.line_item.applicable_rate))

              #add to per patient total for whole visit (all services)
              visit_per_patient_totals[visit_index] ||= 0
              visit_per_patient_totals[visit_index] += per_patient
              
              #add to all patients total for whole visit (all services)
              qty > 0 ? qty : ""

            end
            row << line_per_patient_total
            row << line_per_study_total

            # row_styles = Array.new(row.size,nil)
            # row_styles[2] = @styles.service_cost_money
            # row_styles[3] = @styles.service_cost_money
            #
            # row_styles[-2] = @styles.money
            # row_styles[-1] = @styles.money
            row_styles = Array.new(row.size, @styles.visit_count)
            row_styles[0] = nil
            row_styles[1] = nil
            row_styles[2] = @styles.service_cost_money
            row_styles[3] = @styles.service_cost_money
            row_styles[4] = nil
            row_styles[-2] = @styles.money
            row_styles[-1] = @styles.money

            row_widths = Array.new(row.size, 5)
            row_widths[0] = :ignore
            row_widths[1] = :auto
            row_widths[-2] = 5
            row_widths[-1] = 5
          
            sheet.add_row(
              row,
              :style => row_styles,
              :widths => row_widths
            )
            service_per_patient_subtotal += line_per_patient_total
            service_per_study_subtotal += line_per_study_total
          end

          # sub total for the service
          sheet.add_row(
            Array.new(5 + visit_per_patient_totals.size, nil) + [service_per_patient_subtotal, service_per_study_subtotal],
            :style => @styles.money_total
          )

          #blank spacer row
          sheet.add_row(
            Array.new(5 + visit_per_patient_totals.size + 2, nil),
            :style => @styles.spacer_row
          )
        end # end of visit line items

        # Summarizing the visit
        sheet.add_row(
          [nil,nil,nil,nil,nil] + headers[5..-3],
          :style => [nil,nil,nil,nil,nil] + Array.new(visit_per_patient_totals.size,@styles.visit_header)
        )

        visit_summary_style = [nil,nil,nil,@styles.visit_summary_row_header,nil] + Array.new(visit_per_patient_totals.size,@styles.money_total)

        unless visit_per_patient_totals.empty?
          #print row of per patient totals by visit
          sheet.add_row(
            [nil,nil,nil,"Per Patient",nil] + visit_per_patient_totals, 
            :style => visit_summary_style
          )

          #print row of all patients totals by visit
          sheet.add_row(
            [nil,nil,nil,"All Patients",nil] + visit_per_patient_totals.map{|v| v * arm.subject_count },
            :style => visit_summary_style)
          widths = [30,15,8,8,8] + Array.new(visit_per_patient_totals.size, 8)
          sheet.column_widths(*widths)
        end

        #blank
        sheet.add_row([])

        #total study cost
        sheet.add_row(
          [nil,nil,nil,"Total Study Cost",nil, visit_per_patient_totals.map{|v| v * arm.subject_count}.sum],
          :style => visit_summary_style
        )

      end

    end

    def pppv_line_item_visits(arm)

      Dashboard::ServiceCalendars.pppv_line_items_visits_to_display(
        arm, 
        @service_request,
        nil,
        merged: true,
        statuses_hidden: nil,
        display_all_services: true)
    end

    def eager_loaded_visits(liv)

      liv.ordered_visits.eager_load(
        line_items_visit: {
          line_item: [
            :admin_rates,
            service_request: :protocol,
            service: [
              :pricing_maps,
              organization: [
                :pricing_setups,
                parent: [
                  :pricing_setups,
                  parent: [
                    :pricing_setups,
                    :parent
                  ]
                ]
              ]
            ]
          ]
        }
      )
    end

    def display_org_name_text(org_name, ssr, locked)
      header  = org_name + (ssr.ssr_id ? " (#{ssr.ssr_id})" : "")
      header
    end

    def display_service_rate line_item
      full_rate = line_item.service.displayed_pricing_map.full_rate

      Service.cents_to_dollars(full_rate)
    end
    def display_unit_type(liv)
      liv.line_item.service.displayed_pricing_map.unit_type.gsub("/", "/ ")
    end
  end
end
