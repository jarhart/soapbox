class User < ActiveRecord::Base
  has_many :topics

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :trackable, :omniauthable, :omniauth_providers => [:meetup]

  validates :name, presence: true

  attr_accessible :name, :provider, :uid, :email, :password, :password_confirmation, :remember_me, :organizer

  def self.by_points
    order('points DESC')
  end

  def self.find_for_meetup_oauth(auth, signed_in_resource = nil)
    user = User.where(provider: auth.provider, uid: auth.uid).first

    r = Nestful.get("https://api.meetup.com/2/profiles", format: :json, params: { group_urlname: 'las-vegas-ruby-on-rails', member_id: auth.uid, key: ENV['MEETUP_API_KEY'] })
    role = r['results'][0]['role']
    organizer = (role == 'Co-Organizer' || role == 'Organizer')

    unless user
      user = User.create(name: auth.info.name,
                         provider: auth.provider,
                         uid: auth.uid,
                         organizer: true)
    end

    user.update_attribute(:organizer, organizer)

    user
  end

  def voted_on?(topic)
    topic.voters.where(user_id: id).first || false
  end

  def volunteered_for?(topic)
    topic.volunteers.where(user_id: id).first || false
  end

  def vote_on!(topic)
    return false if voted_on?(topic)
    topic.voters.create(user_id: id)
  end

  def volunteer_for!(topic)
    return false if volunteered_for?(topic)
    topic.volunteers.create(user_id: id)
  end
end