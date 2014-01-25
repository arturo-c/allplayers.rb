module AllPlayers
  module Forms
    def get_submission(form_uuid, submission_id = nil, user_uuid = nil, key_values = {}, html = 0)
      if submission_id.nil?
        get 'forms/' + form_uuid + '/submissions', {:user_uuid => user_uuid, :key_values => key_values, :html => html}
      else
        get 'forms/' + form_uuid + '/submissions/' + submission_id.to_s, {:html => html, :user_uuid => user_uuid}
      end
    end

    def assign_submission(form_uuid, submission_id, user_uuid, html = 0)
      post 'forms/' + form_uuid + '/assign_submission/' + submission_id.to_s, {:user_uuid => user_uuid, :html => html}
    end

    def create_submission(form_uuid, data = {}, user_uuid = nil)
      formatted_data = {}
      data.each do |cid, value|
        formatted_data.merge!(cid => {:value => {0 => value}})
      end
      submission = {:data => formatted_data}

      unless user_uuid.nil?
        submission.merge!(:user_uuid => user_uuid)
      end
      post 'submissions', {:webform => form_uuid, :submission => submission}
    end

    def get_webform(form_uuid)
      get 'webforms/' + form_uuid
    end
  end
end
