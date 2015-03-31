module AuthenticationHelper
  def encryption(data)
    cipher = OpenSSL::Cipher.new("AES-256-CBC")
    cipher.encrypt
    #p App_Password::Size
    key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(App_Password::Key,App_Password::Length, App_Password::Size, cipher.key_len)
    cipher.key = key
    iv = cipher.random_iv
    cipher.iv = iv

    # Encrypt the data using cipher
    encrypted_data = cipher.update(data)<< cipher.final

    #convert to hex value
    encoded =  encrypted_data.unpack('H*').first
    final_iv =  iv.unpack('H*').first

    { encoded_verification_code: encoded, iv: final_iv}
  end

  def decryption(iv,encrypt_data)
    cipher = OpenSSL::Cipher.new("AES-256-CBC")
    key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(App_Password::Key, App_Password::Length, App_Password::Size, cipher.key_len)
    cipher.key = key

    #convert to char value
    cipher.iv = iv.scan(/../).map{|b|b.hex}.pack('c*')
    data = encrypt_data.scan(/../).map{|b|b.hex}.pack('c*')
    plain_text = cipher.update(data) << cipher.final
  end

end
