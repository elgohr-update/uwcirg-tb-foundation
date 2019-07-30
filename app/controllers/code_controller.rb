require "json"
require "bcrypt"
require "securerandom"
require "fileutils"
require "base64"

# Run code.
#
# Just... run the code.
class CodeController < ApplicationController
  before_action :set_cors_headers, only: [:evaluate, :cors_preflight]
  skip_before_action :verify_authenticity_token

  def evaluate
    code = params.permit(:code)[:code]

    convey(results_of_executing(code))
  end

  #Better error handleing really should be added here

  def add_strip_report
    userID= params["userID"]
    picture = Base64.decode64(params["photo"]);
    baseURL = ENV["URL_API"]

    temp = Participant.find_by(uuid: userID).strip_reports.new(
      photo: params["photo"],
      timestamp: params["timestamp"],
    )   

    date = Time.now.strftime("%Y%m%dT%H%M%S")
    filename = "strip_report_#{StripReport.all.count + 1}_#{date}"
    
    temp.url_photo = "#{baseURL}/photo/#{userID}/#{filename}"

    temp.save


    photoDir = "/ruby/backend/upload/strip_photos/#{userID}"

    #Make sure directory for photos exists
    FileUtils.mkdir_p photoDir

    File.open("#{photoDir}/#{filename}.png", "wb") do |file|
    file.write(picture)
    end

    tosend = { "filename" => temp.url_photo, "userID" => userID, "id" => temp.id}

    render(json: tosend.to_json, status: 200)
  end

  def get_photo
    name = params[:filename]
    userID= params[:userID]

    photoDir = "/ruby/backend/upload/strip_photos/#{userID}"

    send_file "#{photoDir}/#{name}.png", type: 'image/png', disposition: 'inline'

  end

  def post_new_coordinator

    newCoordinator = Coordinator.new(
      name: params["name"],
      email: params["email"],
      password_digest:  BCrypt::Password.create(params["password"]),
      uuid: SecureRandom.uuid,
    )

    newCoordinator.save

    render(json: newCoordinator.to_json, status: 200)
  end

  def cors_preflight
    response.set_header("Allow", "POST")
    response.set_header("Access-Control-Allow-Origin", "*")
    response.set_header("Access-Control-Allow-Headers", "Content-Type") 
  end


  def get_all_strip_reports
      rows = StripReport.order("created_at DESC")
      render(json: rows.as_json(:except => [:photo]), status: 200)
  end

  private

  def set_cors_headers
    response.set_header("Allow", "POST")
    response.set_header("Access-Control-Allow-Origin", "*")
    response.set_header("Access-Control-Allow-Headers", "Content-Type")
  end

  def convey(information)

    render json: information.to_json(:except => :photo)
  end

  # Primitives are always "valid",
  # and structures built of "valid" objects *tend* to be valid as well.
  def valid?(information)
    # Our understanding of "validity" will need to be tested.

  end

  def results_of_executing(code)
    eval(code)
  end

end
