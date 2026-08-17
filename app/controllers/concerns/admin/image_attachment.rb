module Admin::ImageAttachment
  private

  # アップロード画像を1000x1000以内に縮小してから添付する（保存容量の抑制）
  def attach_resized_image(record, image)
    return if image.blank?

    resized_image = ImageProcessing::Vips.source(image.tempfile).resize_to_limit(1000, 1000).call

    record.image.attach(
      io: resized_image,
      filename: image.original_filename,
      content_type: image.content_type
    )
  end
end
