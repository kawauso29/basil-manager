module Admin::FlashMessages
  private

  def admin_flash_now_alert(text)
    flash.now[:alert] = text.to_s
  end
  def admin_flash_notice(text)
    flash[:notice] = text.to_s
  end

  def admin_create_success_message
    flash[:notice] = '作成しました'
  end
  def admin_create_error_message(model)
    flash.now[:alert] = "作成に失敗しました #{model.errors.full_messages.join(', ')}"
  end
  def admin_destroy_success_message
    flash[:notice] = '削除しました'
  end
  def admin_destroy_error_message(model)
    flash.now[:alert] = "削除に失敗しました #{model.errors.full_messages.join(', ')}"
  end

  def admin_update_success_message(model)
    changes = model.saved_changes.except("updated_at")
    if changes.present?
      message = changes.map do |key, (old_value, new_value)|
        attribute_name = model.class.human_attribute_name(key)
        "#{attribute_name}: #{old_value} → #{new_value}"
      end.join(", ")

      flash[:notice] = "#{message}に更新しました"
    else
      flash[:notice] = "変更はありませんでした"
    end
  end
  def admin_update_error_message(model)
    flash.now[:alert] = "更新に失敗しました #{model.errors.full_messages.join(", ")}"
  end

end
