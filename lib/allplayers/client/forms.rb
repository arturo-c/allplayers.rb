module AllPlayers
  module Forms
    def get_submission(form_uuid, submission_uuid = nil, user_uuid = nil, form_keys = {})
      if submission_uuid.nil?
        get 'forms/' + form_uuid + '/submission', {:user_uuid => user_uuid, :form_keys => form_keys}
      else
        get 'forms/' + form_uuid + '/submission/' + submission_uuid.to_s, {:user_uuid => user_uuid}
      end
    end

    def assign_submission(form_uuid, submission_uuid, user_uuid)
      post 'forms/' + form_uuid + '/assign_submission/' + submission_uuid.to_s, {:user_uuid => user_uuid}
    end

    def create_submission(form_uuid, data = {}, user_uuid = nil)
      submission = {:data => data}

      unless user_uuid.nil?
        submission.merge!(:user_uuid => user_uuid)
      end
      post 'submissions', {:webform => form_uuid, :submission => submission}
    end

    def delete_submission(form_uuid)
      delete 'submissions/' + form_uuid
    end

    def get_webform(form_uuid)
      get 'webforms/' + form_uuid
    end

    def get_submission_by_uuid(submission_uuid)
      get 'submissions/' + submission_uuid
    end
  end
end
