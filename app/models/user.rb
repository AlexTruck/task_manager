class User < ActiveRecord::Base
  attr_accessor :activation_token
  before_save   :downcase_email
  before_create :create_remember_token
  before_create :create_activation_digest

  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates_presence_of :first_name, :last_name, :email
  validates :email, format: { with: EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, length: { minimum: 8 }

  def User.new_remember_token
    SecureRandom.urlsafe_base64
  end

  def User.encrypt(token)
    Digest::SHA1.hexdigest(token.to_s)
  end

  def authenticated?(attribute, token)
    encrypt = send("#{attribute}_encrypt")
    return false if encrypt.nil?
    BCrypt::Password.new(encrypt).is_password?(token)
  end

  def activate
    update_attribute(:activated, true)
    update_attribute(:activated_at, Time.zone.now)
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  private

  def downcase_email
    self.email = email.downcase
  end

  def create_remember_token
    self.remember_token = User.encrypt(User.new_remember_token)
  end

  def create_activation_digest
    self.activation_token  = User.new_remember_token
    self.activation_digest = User.encrypt(activation_token)
  end
end