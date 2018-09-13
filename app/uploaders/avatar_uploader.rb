class AvatarUploader < CarrierWave::Uploader::Base
  # Include RMagick or MiniMagick support:
  include CarrierWave::RMagick
  include CarrierWave::MiniMagick


  storage :fog

  def initialize(*)
    super

    self.fog_credentials = {
        :provider               => 'AWS',              # required
        :aws_access_key_id      => 'AKIAIJMZ5RLXRO6LJHPQ',     # required
        :aws_secret_access_key  => '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',    # required
        :region => "ap-southeast-1",
    }
    if Rails.env.development?
      self.fog_directory = "hivedevavatars"
    elsif Rails.env.staging?
      self.fog_directory = "hivestagingavatars"
    elsif Rails.env.production?
      self.fog_directory = "hiveproductionavatars"
    end
  end

  version :medium do
    process :resize_to_fit => [300, 300]
    def full_filename (for_file = model.logo.file)
      file_name =  super.chomp(File.extname(super))
      names= file_name.split("_")
      names[1] + '_m.png'
    end
  end

  version :small do
    process :resize_to_fit => [150,150]
    def full_filename (for_file = model.logo.file)
      file_name =  super.chomp(File.extname(super))
      names= file_name.split("_")
      names[1] + '_s.png'
    end
  end

  def store_dir
    nil
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
