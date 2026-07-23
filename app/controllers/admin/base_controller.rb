class Admin::BaseController < ApplicationController
  layout "admin"
  include Admin::FlashMessages
  http_basic_authenticate_with(
    name: Rails.application.credentials.dig(:admin, :user),
    password: Rails.application.credentials.dig(:admin, :password)
  )
end
