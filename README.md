# Project Vinyl: Premium Pony Tunes

Built using Ruby on Rails and MySQL.

## Deployment

You need a key installed on the server you target, and the git remote added to your configuration.

    git remote add production vinylscratch@<serverip>:ProjectVinyl/

The syntax is:

    git push production master

And if everything goes wrong:

    git reset HEAD^ --hard
    git push -f production master

(to be repeated until it works again)
