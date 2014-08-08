# encoding: utf-8

class PhotoUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  #include CarrierWave::RMagick
  include CarrierWave::RMagick
  include CarrierWave::MimeTypes
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  #storage :file
  storage :fog

  process :set_content_type
  #process :quality => 40

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:

  def initialize(*)
    super

    self.fog_credentials = {
        :provider               => 'AWS',              # required
        :aws_access_key_id      => 'AKIAIJMZ5RLXRO6LJHPQ',     # required
        :aws_secret_access_key  => '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',    # required
        :region => "ap-southeast-1",
    }
    if Rails.env.development?
      self.fog_directory = "hivedevimages"
    elsif Rails.env.staging?
      self.fog_directory = "hivestagingimages"
    elsif Rails.env.production?
      self.fog_directory = "hiveproductionimages"
    end
  end

  version :medium do
    process :resize_to_fit => [300, 300]
    def full_filename (for_file = model.logo.file)
      file_name =  super.chomp(File.extname(super))
      names= file_name.split("_")
      names[1] + '_m.jpg'
    end
  end

  version :small do
    process :resize_to_fit => [150,150]
    def full_filename (for_file = model.logo.file)
      file_name =  super.chomp(File.extname(super))
      names= file_name.split("_")
      names[1] + '_s.jpg'
    end
  end

  def store_dir
    nil
  end

  def get_geometry
    if (@file)
      #img = ::Magick::Image::read(@file.file).first
      img = ::MiniMagick::Image::read(File.binread(@file.file))
      @geometry = [ img[:width], img[:height]]
    end
  end

  #def filename
  #  p File.basename(super)
  #  super.chomp(File.extname(super)) + '_s.jpg'
  #end

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
