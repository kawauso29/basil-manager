module Admin::ImageAttachment
  private

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
