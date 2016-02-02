require 'rails_helper'

RSpec.describe 'dashboard index', js: :true do
  let_there_be_lane
  fake_login_for_each_test

  def visit_protocols_index_page
    @page = Dashboard::Protocols::IndexPage.new
    @page.load
    wait_for_javascript_to_finish
  end

  describe 'Protocols list' do
    describe 'defaults' do
      it 'should not display archived Protocols' do
      end

      it 'should not display Protocols for which user is not an associated user' do
      end

      it 'should not display Protocols for which user has \'none\' rights' do
      end      
    end
    describe 'archive button' do
      context 'archived Project' do
        before(:each) do
          @protocol = create(:protocol_federally_funded, :without_validations, primary_pi: jug2, type: 'Project', archived: true)
          visit_protocols_index_page
        end

        it "should display 'Unarchive Project'" do
          expect(@page.protocols.first.archive_button.text).to eq 'Unarchive Project'
        end

        context 'User clicks button' do
          it 'should unarchive Project' do
            @page.protocols.first.archive_button.click
            wait_for_javascript_to_finish
            expect(protocol.reload.archived).to be false
          end

          it 'should change button text to "Archive Project"' do
            @page.protocols.first.archive_button.click
            wait_for_javascript_to_finish
            expect(@page.protocols.first.archive_button.text).to eq 'Archive Project'
          end
        end
      end

      context 'unarchived Project' do
        let!(:protocol) { create(:protocol_federally_funded, :without_validations, primary_pi: jug2, type: 'Project', archived: false) }
        before(:each) { visit_protocols_index_page }

        it "should display 'Archive Project'" do
          expect(@page.protocols.first.archive_button.text).to eq 'Archive Project'
        end

        context 'User clicks button' do
          it 'should archive Project' do
            @page.protocols.first.archive_button.click
            wait_for_javascript_to_finish
            expect(protocol.reload.archived).to be true
          end

          it 'should change button text to "Unarchive Project"' do
            @page.protocols.first.archive_button.click
            wait_for_javascript_to_finish
            expect(@page.protocols.first.archive_button.text).to eq 'Unarchive Project'
          end
        end
      end

      context 'archived Study' do
        let!(:protocol) { create(:protocol_federally_funded, :without_validations, primary_pi: jug2, type: 'Study', archived: true) }
        before(:each) { visit_protocols_index_page }

        it "should display 'Unarchive Study'" do
          expect(@page.protocols.first.archive_button.text).to eq 'Unarchive Study'
        end

        context 'User clicks button' do
          it 'should unarchive Study' do
            @page.protocols.first.archive_button.click
            wait_for_javascript_to_finish
            expect(protocol.reload.archived).to be false
          end

          it 'should change button text to "Archive Study"' do
            @page.protocols.first.archive_button.click
            wait_for_javascript_to_finish
            expect(@page.protocols.first.archive_button.text).to eq 'Archive Study'
          end
        end
      end

      context 'unarchived Study' do
        let!(:protocol) { create(:protocol_federally_funded, :without_validations, primary_pi: jug2, type: 'Study', archived: false) }
        before(:each) { visit_protocols_index_page }

        it "should display 'Archive Study'" do
          expect(@page.protocols.first.archive_button.text).to eq 'Archive Study'
        end

        context 'User clicks button' do
          it 'should archive Study' do
            @page.protocols.first.archive_button.click
            wait_for_javascript_to_finish
            expect(protocol.reload.archived).to be true
          end

          it 'should change button text to "Unarchive Study"' do
            @page.protocols.first.archive_button.click
            wait_for_javascript_to_finish
            expect(@page.protocols.first.archive_button.text).to eq 'Unarchive Study'
          end
        end
      end
    end

    describe 'requests button' do
      let!(:protocol) { create(:protocol_federally_funded,  :without_validations, primary_pi: jug2, type: 'Study', archived: false) }

      context 'Protocol has no ServiceRequests' do
        before(:each) { visit_protocols_index_page }

        it 'should not display button' do
          expect(@page.protocols.first).to have_no_requests_button
        end
      end

      context 'Protocol has a SubServiceRequest' do
        context 'user clicks the requests button' do
          let!(:service_request) { create(:service_request_without_validations, protocol: protocol, service_requester: jug2) }
          let!(:sub_service_request) { create(:sub_service_request, ssr_id: '0001', service_request: service_request, organization: create(:organization)) }
          before(:each) do
            visit_protocols_index_page
            @protocol_in_list = @page.protocols.first
          end

          before(:each) { @protocol_in_list.requests_button.click }

          it 'should open a modal' do
            expect(@page).to have_requests_modal
          end
        end
      end
    end

    describe 'requests modal' do
      let!(:protocol) { create(:protocol_federally_funded,  :without_validations, primary_pi: jug2, type: 'Study', archived: false) }
      let!(:service_request_with_ssr) { create(:service_request_without_validations, protocol: protocol, service_requester: jug2) }
      let!(:sub_service_request) { create(:sub_service_request, ssr_id: '0001', service_request: service_request, organization: create(:organization)) }
      let!(:service_request_wo_ssr) { create(:service_request_without_validations, protocol: protocol, service_requester: jug2) }
      before(:each) do
        visit_protocols_index_page
        @page.protocols.first.requests_button.click
        @requests_modal = @page.requests_modal
      end

      it 'should be titled by the Protocol\'s short title' do
        expect(@requests_modal.title.text).to eq protocol.short_title
      end

      it 'should list the associated ServiceRequests that have SubServiceRequests' do
        expect(@requests_modal.service_requests.first.pretty_ssrid.text).to eq "#{protocol.id}-#{service_request_with_ssr.ssr_id}"
      end

      it 'should not list SubServiceRequests in first_draft' do
      end

      context 'user can edit ServiceRequest' do
        it 'should display \'Edit Original\' button' do
        end
      end

      context 'user cannot edit ServiceRequest' do
        it 'should not display \'Edit Original\' button' do
        end
      end
    end
  end
end
