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

require 'rails_helper'

RSpec.describe "Ask a question", js: true do
  before :each do
    visit root_path
    find('.ask-a-question-button').click
  end

  describe 'clicking the button' do

    it 'should display the ask a question form' do
      find('#ask-a-question-form').visible?
    end
  end

  describe 'form validation' do

    it "should not show the error message if the email is correct" do
      find_by_id('quick_question_email').click
      page.find('#quick_question_email').set 'juan@gmail.com'
      find('#submit_question').click
      expect(find('#ask-a-question-form', visible: false).visible?).to eq(false)
    end

    it "should require an email" do
      find_by_id('quick_question_email').click()
      find('#submit_question').click()
      expect(find_by_id('ask-a-question-form').visible?).to eq(true)
      expect(page).to have_content("Valid email address required.")
    end

    it "should display the error and not allow the form to submit if the email is not valid" do
      find_by_id('quick_question_email').click()
      page.find('#quick_question_email').set 'Pappy'
      find('#submit_question').click()
      expect(find_by_id('ask-a-question-form').visible?).to eq(true)
      expect(page).to have_content("Valid email address required.")
    end
  end
end
