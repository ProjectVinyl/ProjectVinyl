# Be sure to restart your server when you modify this file.

if Rails.env.production?
    Rails.application.config.session_store :cookie_store,
                      key: '_projectvinyl_session',
                      domain: '.projectvinyl.net'
else
    Rails.application.config.session_store :cookie_store,
                      key: '_projectvinyl_session',
                      domain: '.lvh.me'
end
