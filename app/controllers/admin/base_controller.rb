class Admin::BaseController < ApplicationController
  layout "admin"
  include Admin::FlashMessages
  http_basic_authenticate_with(
    name: Rails.application.credentials.dig(:admin, :user),
    password: Rails.application.credentials.dig(:admin, :password)
  )

  private

  # 詳細画面の「前へ/次へ」用に、主キー順で前後のレコードを取得する
  def set_record_navigation(record, scope: record.class.all)
    primary_key = record.class.primary_key
    primary_key_column = record.class.arel_table[primary_key]
    primary_key_value = record.public_send(primary_key)

    @previous_record = scope
                       .where(primary_key_column.lt(primary_key_value))
                       .order(primary_key => :desc)
                       .first
    @next_record = scope
                   .where(primary_key_column.gt(primary_key_value))
                   .order(primary_key => :asc)
                   .first
  end
end
