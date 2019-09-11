class ParticipantController < AuthenticatedController
    before_action :auth_participant
    
    #Require coordinator authentication for user password reset
    before_action :auth_coordinator, :only => [:reset_password]
    skip_before_action :verify_authenticity_token

    def get_current_participant
        current = Participant.find(@current_user.id);
        render( json: current.to_json, status: 200)
    end

    def create_note
        new_note = @current_user.notes.create!({title: params[:title], text: params[:text]});
        all_notes = @current_user.notes
        render(json: all_notes, status: 200)
    end

    def update_information
        account = Participant.update(@current_user.id,update_params)
        render(json: account.to_json, status: 200)
    end

    def report_medication
        new_report = @current_user.medication_reports.create!({timestamp: params[:timestamp],
         took_medication: params[:took_medication],
          not_taking_medication_reason: params[:not_taking_medication_reason]})
        
        all_reports = @current_user.medication_reports
        render(json: all_reports, status: 200)
    end

    def report_symptoms
        filtered_params = params.permit([:nausea,
            :nausea_rating,
            :redness,
            :hives,
            :fever,
            :appetite_loss,
            :blurred_vision,
            :sore_belly,
            :yellow_coloration,
            :difficulty_breathing,
            :facial_swelling,
            :dizziness,
            :headache,
            :other,
        :timestamp])

        new_report = @current_user.symptom_reports.create!(filtered_params.to_h)

        all_reports = @current_user.symptom_reports
        render(json: all_reports, status: 200);
    end

    def update_password
        if params["password"] == params["password_check"]

            if( BCrypt::Password.new(@current_user.password_digest) == params["current_password"])
                Participant.update(@current_user.id, {password_digest:  BCrypt::Password.create(params["password"])})
                render(json: {message: "Password update sucessful"}, status: 200)
            else
                render(json: {error: "Incorrect current password"},status: 400)
            end
        else 
            render(json: {error: "New password and password_check do not match"},status: 400)
        end

    end

    private

    #Protect against updating with blank information
    def  update_params
      params.
        permit(:name, :phone_number,:treatment_start).
        delete_if {|key, value| value.blank? }
    end


end