module AdminRequestHelpers
  def admin_headers
    user = Rails.application.credentials.dig(:admin, :user)
    password = Rails.application.credentials.dig(:admin, :password)

    {
      "HTTP_AUTHORIZATION" =>
        ActionController::HttpAuthentication::Basic.encode_credentials(user, password)
    }
  end
end

RSpec.configure do |config|
  config.include AdminRequestHelpers, type: :request
end