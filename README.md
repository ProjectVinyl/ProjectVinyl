# Project Vinyl: Premium Pony Tunes

Project Vinyl is a rails-hosted video streaming platform.

Built using Ruby on Rails and PostgreSQL.

## Version Information
Ruby: 2.6.3 \
Rails: 5.1.6.2 \
Elasticsearch: 6.8.0 \
Postgres: 12

## Setup

### Presequisites

 - Docker (`apt-get install docker`)
 - Docker Compose (`apt-get install docker-compose`)

    git clone git@github.com:ProjectVinyl/ProjectVinyl.git
    cd ProjectVinyl
    ./ducker compose

### Docker

Developing with project vinyl is (somewhat) easy.
Simply run `./ducker compose` and the project and its dependencies will be built and deployed.

The included docker image includes:
 - Project Vinyl itself (git directory mounted inside container) (localhost:8080)
 - postgres-12
 - elasticsearch
 - redis

Note:

    On the first run you may need to manually load the database.
    This can be done by logging into the projectvinyl container and running `rails db:create`
    and `rails db:schema:load` which will give you a basic starting database.

    ./ducker shell projectvinyl-app-1
      projectvinyl:~/ProjectVinyl$ eval "$(rbenv init - bash)"
      projectvinyl:~/ProjectVinyl$ rails db:create
      projectvinyl:~/ProjectVinyl$ rails db:schema:load

