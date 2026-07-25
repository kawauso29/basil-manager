module AdminRequestHelpers
  def admin_headers
    user = ENV.fetch("ADMIN_BASIC_AUTH_USER") { Rails.application.credentials.dig(:admin, :user) }
    password = ENV.fetch("ADMIN_BASIC_AUTH_PASSWORD") { Rails.application.credentials.dig(:admin, :password) }

    {
      "HTTP_AUTHORIZATION" =>
        ActionController::HttpAuthentication::Basic.encode_credentials(user, password)
    }
  end
end

RSpec.configure do |config|
  config.include AdminRequestHelpers, type: :request
end
