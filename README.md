# Reference Tracking [![Build Status](https://secure.travis-ci.org/svenfuchs/reference_tracking.png?branch=master)](http://travis-ci.org/svenfuchs/reference_tracking)

STATUS: pre-alpha, [readme-driven](http://tom.preston-werner.com/2010/08/23/readme-driven-development.html)

`reference_tracking` aims to provide a mechanism to track objects/methods accessed on a certain page/view. On top of this we should be able to implement automatic and easy to use cache invalidation.

Consider a typical blog application where an index view displays a list of blog posts and a show view displays a single post. Both views are cached somewhere as a whole (e.g. using Rack::Cache). Now, when the post gets updated (e.g. the title was changed) then both pages need to be expired/purged from the cache.

Using `reference_tracking` the application could be set up so that both the index and show views track access to the posts collection and/or post model and emit "tags" for the current page that indicate wheather or not the models were used on the page. Now, when the post in question gets updated the application can purge all pages from the cache that have a tag indicating that they have used the given post.

In this simple scenario this is just convenient. Developers don't need to hardcode and maintain so much knowledge about which models are being used in which views in order to invalidate the cache accordingly.

In other scenarios developers can't even know upfront which pages will use a certain model (so that they also can't know in advance which pages to invalidate when the model got updated). Consider reusable cells or html snippets that are inserted using esi or some other mechanism. There might be a "recent blog posts" cell that designers or even application users can use in arbitrary places.

## Usage

Currently `reference_tracking` assumes that you do **not** use instance variables in your views but use helper methods implemented on the controller instead. (I'll accept patches that add tracking for instance variables if that doesn't add too much load.)

So, we could make the controller track access to methods like this:

    class PostsController < ApplicationController
      tracks :post

      def post
        Post.find(1)
      end
      helper_method :post
    end

Now, when the view accesses the post method on the controller a reference to it will be stored:

    <%= post.title %> # stores a reference to the post instance

Once the view has rendered these references will then be transformed to "tags" and stored to the response headers. A Rack middleware can then extract these headers and persist the tags for the current url.

Some examples for how the current API supports tagging in a more finegrained manner:

     tracks :post                          # => post-1
     tracks 'post.title'                   # => post-1.title
     tracks :post => '.title'              # => post-1.title
     tracks :post => :blog                 # => blog-1
     tracks :post => ['.title', '.body']   # => post-1.title, post-1.body
     tracks :post => [:blog, '.title']     # => blog-1, post-1.title
     tracks :post => { :blog => '.title' } # => blog-1.title
     tracks :blog => :posts                # => post-1, post-2, post-3, ...

