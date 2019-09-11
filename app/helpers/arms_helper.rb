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

module ArmsHelper
  def arm_name_helper(arm)
    if arm.name == 'Screening Phase'
      content_tag :span, title: t('arms.tooltips.screening'), data: { toggle: 'tooltip', container: 'body', boundary: 'window' } do
        icon('fas', 'info-circle text-primary mr-1') + arm.name
      end
    else
      arm.name
    end
  end

  def arms_actions(arm, opts={})
    [
      arms_edit_button(arm, opts),
      arms_delete_button(arm, opts)
    ].join('')
  end

  def arms_edit_button(arm, opts={})
    link_to icon('far', 'edit'), edit_arm_path(arm, srid: opts[:srid]), remote: true, class: ['btn btn-warning mr-1', opts[:editable] ? '' : 'disabled'], title: t('arms.edit'), data: { toggle: 'tooltip' }
  end

  def arms_delete_button(arm, opts={})
    link_to icon('fas', 'trash-alt'), arm_path(arm, srid: opts[:srid]), remote: true, method: :delete,
    class: ['btn btn-danger', opts[:editable] && opts[:count] > 1 ? '' : 'disabled'],
    title: t('arms.delete'), data: { toggle: 'tooltip', confirm_swal: 'true' }
  end
end
