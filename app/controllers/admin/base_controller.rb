class Admin::BaseController < ApplicationController
  layout "admin"
  include Admin::FlashMessages
end
