module Jobs

  # A daily job that will enqueue digest emails to be sent to users
  class EnqueueDigestEmails < Jobs::Base

    def execute(args)
      target_users.each do |u|
        Jobs.enqueue(:user_email, type: :digest, user_id: u.id)
      end
    end

    def target_users
      # Users who want to receive emails and haven't been emailed int he last day
      query = User.select(:id)
                  .where(email_digests: true)
                  .where("COALESCE(last_emailed_at, '2010-01-01') <= CURRENT_TIMESTAMP - ('1 DAY'::INTERVAL * digest_after_days)")
                  .where("COALESCE(last_seen_at, '2010-01-01') <= CURRENT_TIMESTAMP - ('1 DAY'::INTERVAL * digest_after_days)")

      # If the site requires approval, make sure the user is approved
      if SiteSetting.must_approve_users?
        query = query.where("approved OR moderator OR admin")
      end

      query
    end

  end

end
