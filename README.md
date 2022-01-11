# OmniAuth Strategy for Krystal Identity

Krystal Identity is the single sign on service for [Krystal](https://k.io). You can use this provider to authenticate your own applications using OmniAuth.

To begin, you'll need to create an OAuth Application through the [Krystal Identity](https://identity.k.io). Once you've done this, you'll need to provide your the client ID and secret provided within the web interface.

Once you have this, you can add the provider to your OmniAuth configuration.

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :krystal, ENV['KRYSTAL_IDENTITY_CLIENT_ID'], ENV['KRYSTAL_IDENTITY_CLIENT_SECRET']
end
```

