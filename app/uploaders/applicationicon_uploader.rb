# encoding: utf-8

class ApplicationiconUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  #storage :file
  storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    nil
  end

  #process :set_content_type
  #process :quality => 40   #define the quality of image
  process :resize_to_fill => [100, 100]
  process :convert => 'png'

  def get_geometry
    if (@file)
      #img = ::Magick::Image::read(@file.file).first
      img = ::MiniMagick::Image::read(File.binread(@file.file))
      @geometry = [ img[:width], img[:height]]
    end
  end

  #generate Unique filename
  def filename
    "#{super.chomp(File.extname(super))}-#{secure_token}.png" if original_filename.present? and super.present?
  end

  protected
  #generate random number to get unique filename
  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
  end

  def cache_dir
    'tmp'
  end

  def move_to_cache
    true
  end


  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

end
