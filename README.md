# OmniAuth Strategy for Krystal Identity

[![Gem Version](https://badge.fury.io/rb/omniauth-krystal.svg)](https://badge.fury.io/rb/omniauth-krystal)

Krystal Identity is the single sign on service for [Krystal](https://k.io). You can use this provider to authenticate your own applications using OmniAuth.

To begin, you'll need to create an OAuth Application through the [Krystal Identity](https://identity.k.io). Once you've done this, you'll need to provide your the client ID and secret provided within the web interface.

Once you have this, you can add the gem to your `Gemfile` and add the provider to your OmniAuth configuration.

```
$ bundle add omniauth-krystal
```

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :krystal, ENV['KRYSTAL_IDENTITY_CLIENT_ID'], ENV['KRYSTAL_IDENTITY_CLIENT_SECRET']
end
```

## Identity-initiated logins

Krystal Identity can initiate logins to applications. This allows users to click a link in the Krystal Identity Dashboard to open up an application they have previously authorised. This is done by Identity beginning the OAuth flow resulting in the request arriving at the OAuth callback URL within the application. The purpose of this middleware is to avoid issues caused by CSRF protections within OmniAuth. The `state` parameter sent with the callback is a JWT token signed by Identity allowing the application to verify the request came from Identity and thus is safe to accept whereas it would normally be rejected.

```ruby
Rails.application.config.middleware.insert_before OmniAuth::Builder,
                                                  OmniAuth::Krystal::InitiatedLoginMiddleware
```

Some additional options can be provided to this:

- `:provider_name` - the name of the Krystal Identity provider (defaults to `krystal`)
- `:identity_url` - the URL to the root of Identity (defaults to `https://identity.k.io`)
- `:anti_replay_expiry_seconds` - the number of seconds to keep anti-replay tokens (defaults to `60`)
- `:redis` - a Redis client to use for storing anti-replay tokens (defaults to `nil`)
