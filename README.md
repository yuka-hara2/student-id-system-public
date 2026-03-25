# README

This README would normally document whatever steps are necessary to get the
application up and running.

## Ruby version
ruby-3.4.4

## Configuration
### Host
Just change to your host. ActiveStorage refers to here.
```
config.action_controller.default_url_options = { host: 'localhost:3000', protocol: 'http' }
```

### Logos
Put your logo in public folder. Name it as "school-logo.png".
Put your approval stamp in public folder. Name it as "school-stamp.png".
Put your favicon.ico in app/assets/images.

### Description of sensitive information
Create file(config/settings.local.yml) to describe sensitive information to be printed on the back of the ID card.
```
default: &default
  school:
    ministry_in_charge: ""
    name: ""
    name_en: ""
    address: ""
    phone_1: ""
    phone_2: ""
    phone_3: ""
development:
  <<: *default
production:
  <<: *default


```


## Database creation
Please follow the basic methods of Rails.
Run the following command to create the database:
```
bin/rails db:create
```

## Database initialization
Please follow the basic methods of Rails.
```
bin/rails db:migrate
```

## Services
- Active Storage (for image uploads)

## Deployment instructions
### Install
- Ruby 3.4
- Rails 8
- SQLite3
- Node.js

### Setup for Application
Open command prompt and execute these commands to prepare for generating PDF in the
application.
```
$ npm init -y
$ npm install puppeteer
```