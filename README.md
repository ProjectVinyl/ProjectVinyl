# Project Vinyl: Premium Pony Tunes
Built using Ruby on Rails and PostgreSQL.

## Prerequisites
First you are recommended to install [ruby-install, and chruby](https://ryanbigg.com/2014/10/ubuntu-ruby-ruby-install-chruby-and-you) before beginning.

* Rails
  * `gem install rails -v 5.1.6.2 --no-document`
* Ruby 2.6.3
  * `sudo ruby-install ruby 2.6.3`
  * `chruby ruby-2.6.3`
* Postgres 11
  * `sudo apt install postgresql-11 libpq-dev`
* [Elasticsearch 6.8.x](https://linuxize.com/post/how-to-install-elasticsearch-on-ubuntu-18-04/)
  * `sudo apt install elasticsearch`
* Redis
  * `sudo apt install redis-server`

## Setup
    git clone git@github.com:ProjectVinyl/ProjectVinyl.git
    cd ProjectVinyl
    sudo ruby-install ruby 2.6.3
    chruby ruby-2.6.3
    bundle install
    rails db:create
    rails db:seed

### Starting
* `foreman start` (will host at localhost:8080)

### Development Database
* `projectvinyl_development`

## Version Information
Ruby: 2.6.3 \
Rails: 5.1.6.2 \
Elasticsearch: 6.8.0 \
Postgres: 11.4

## Deployment
You need a key installed on the server you target, and the git remote added to your configuration.

    git remote add production vinylscratch@<serverip>:ProjectVinyl/

The syntax is:

    git push production master

And if everything goes wrong:

    git reset HEAD^ --hard
    git push -f production master

(to be repeated until it works again)
