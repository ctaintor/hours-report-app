Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_KEY"], ENV["GOOGLE_SECRET"],
    {
      :scope => "userinfo.email,userinfo.profile,calendar",
      :prompt => "select_account consent",
      :image_aspect_ratio => "square",
      :image_size => 100
    }
end
