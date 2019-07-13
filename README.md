# Project Vinyl: Premium Pony Tunes

Built using Ruby on Rails and PostgreSQL.

## Setup

* `git clone git@github.com:ProjectVinyl/ProjectVinyl.git`
* `cd ProjectVinyl`
* `sudo ruby-install ruby 2.6.3`
* `chruby ruby-2.6.3`
* `bundle install`
* < start postgres> (see below)
* < somehow start elasticsearch> (see below)
* ???
* `rails db:create`
* `rails db:seed`
* `foreman start` (will host at localhost:8080)

### ~If~ When foreman fails:
* `rails server` (will host at localhost:3000 - but will be missing risque)

## DB Setup

As Root:
* `echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" >> /etc/apt/sources.list`
   * replace xenial (ubuntu) with the correct term for your distro
* `apt update`
* `apt install postgresql-11 libpq-dev`
* `sudo service postgresql start`
* `sudo -u postgres createuser -s <user-account-name-used-by-the-app>`

Optional:
* `apt install pgadmin3` (though it may not work on Windows. The windows version of Postgres4 may also work, though it didn't for me.)

Alternatively, to access the db through the console:
* `psql projectvinyl_development`

## Elasticsearch (Windows)

You can find elasticsearch (.zip) download over <a href="https://www.elastic.co/downloads/past-releases/elasticsearch-6-8-0">here</a>

* Unzip and run elasticsearch (`elasticsearch-dir/bin/elastisearch.bat`)
* Intall SWL and use the bash terminal (`bash`) for the remaining commands for setup.
* May need to run `sudo service postgresql start` to get the database running.

## Elasticsearch (Linux)

* `apt-get install elasticsearch`
* `sudo service elasticsearch start`

## Version Information

Ruby: 2.6.3
Rails: 5.1.6.2
Elasticsearch: 6.8.0
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
