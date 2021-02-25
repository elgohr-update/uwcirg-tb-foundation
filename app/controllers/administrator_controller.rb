class AdministratorController < UserController
  before_action :auth_admin

  # def auth_admin
  #   #Uses @decoded from User Controller(Super Class)
  #   id = @decoded[:user_id]
  #   @current_user = Administrator.find(id)
  # rescue ActiveRecord::RecordNotFound => e
  #   render json: { errors: "Admin Only Route" }, status: :unauthorized
  # end
  
  def create_practitioner
    newPractitioner = Practitioner.create!(
      email: params[:email],
      password_digest: BCrypt::Password.create(params[:password]),
      family_name: params[:familyName],
      given_name: params[:givenName],
      managing_organization: params[:managingOrganization],
      type: "Practitioner",
    )

    render(json: newPractitioner.as_json, status: 200)
  end

  def patient_list
    render(json: Patient.where('organization_id > 0').order("id DESC").includes("photo_days"),each_serializer: PatientAnonSerializer, status: :ok)
  end

  private

  def create_practitioner_params
    params.require([:email, :password, :familyName, :givenName, :managingOrganization])
  end
end
