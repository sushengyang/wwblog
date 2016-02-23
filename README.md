# wwblog

My personal blog, based on [Middleman](https://middlemanapp.com/).

Let's see if this is better than

- My custom blog
- Wordpress
- Octopress
- Jekyll

# Development

Middleman is a static site generator. But to build and run it:

    $ middleman build
    $ middleman server

Then point ye olde browser at http://localhost:4567.

# Deployment

Deployment is to a Heroku app called `williewheeler`. See [this post](http://12devs.co.uk/articles/204/) for more information on how setup and deployment works.

(Update: I ended up modifying the deployment to use Puma per [this post](http://www.randomerrata.com/articles/2013/middleman-on-heroku/).)

To deploy, just push to Heroku's git repo:

    $ git push heroku master

Behind the scenes, Heroku will run

    $ rake assets:precompile

which runs the Middleman build. (That's how we avoid committing the build assets to Git.)

Then to see the site:

    $ heroku open
