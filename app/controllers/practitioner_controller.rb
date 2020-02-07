require 'aws-sdk'
require 'securerandom'

class PractitionerController < UserController
    before_action :auth_practitioner, :except => [:upload_lab_test,:generate_presigned_url]

    def auth_practitioner
        #Uses @decoded from User Controller(Super Class)
        id = @decoded[:user_id].to_i
        @current_user = Practitioner.find(id)
    
        rescue ActiveRecord::RecordNotFound => e
          render json: { errors: "Practitioner Only Route" }, status: :unauthorized
    end

    def get_current_practitioner
      render(json: @current_user.to_json, status: 200)
    end

    def generate_temp_patient

      #This generates a random 4 digit hex
      code = SecureRandom.hex(10).upcase[0,5]

      newTemp = TempAccount.create(
          phone_number: params[:phoneNumber],
          code_digest: BCrypt::Password.create(code),
          family_name: params[:familyName],
          given_name: params[:givenName],
          organization: params[:organization],
          treatment_start: params[:startDate]
        )

        if newTemp.save
          render(json: {account: newTemp.as_json, code: code}, status: 200)
        else
          @test = newTemp.errors.as_json
          @test = @test.as_json.deep_transform_keys! { |key| key.camelize(:lower) }
          render(json: {error: 422, paramErrors: @test}, status: 422)
        end
    end

    def create_patient
        newPatient = Patient.create!(
        phone_number: params[:phoneNumber],
          password_digest: BCrypt::Password.create(params[:password]),
          family_name: params[:familyName],
          given_name: params[:givenName],
          managing_organization: params[:managingOrganization],
          treatment_start: params[:treatmentStart],
          type: "Patient"
        )
    
        render(json: newPatient.as_json, status: 200)
    end

    def generate_presigned_url

      
      # aws_client = Aws::S3::Client.new(
      #   endpoint: ENV['URL_MINIO'],
      #   access_key_id: ENV['MINIO_ACCESS_KEY'],
      #   secret_access_key: ENV['MINIO_SECRET_KEY'],
      #   force_path_style: true,
      #   region: 'us-east-1'
      # )

      s3 = Aws::S3::Resource.new
      bucket = s3.bucket('lab-strips')
      key = "lab-test-#{SecureRandom.uuid}.jpeg"
      obj = bucket.object(key)
      url = obj.presigned_url(:put)
        

        render json: {url: url, key: key}
    end

    def upload_lab_test

    newTest = LabTest.create!(
       test_id: params[:testId],
       description: params[:description],
       photo_url: params[:photoURL],
       is_positive: params[:isPositive],
       test_was_run: params[:testWasRun],
       minutes_since_test: params[:minutesSinceTest]
      )

      signer = Aws::S3::Presigner.new
      url = signer.presigned_url(:get_object, bucket: "lab-strips", key: newTest.photo_url)


      render(json: newTest.as_json, status: 200)
    end


end