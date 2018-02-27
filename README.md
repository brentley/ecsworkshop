# ecsworkshop

### Setup:

#### Install Hugo:
On a mac:

`brew install hugo`

On Linux:
  - Download from the releases page: https://github.com/gohugoio/hugo/releases/tag/v0.37
  - Extract and save the executable to `/usr/local/bin`

#### Clone this repo:
From wherever you checkout repos:
`git clone git@github.com:brentley/ecsworkshop.git`

#### Clone the theme submodule:
`cd ecsworkshop`

`git submodule update --checkout --recursive`

#### Run Hugo locally:
`npm run server`

#### View Hugo locally:
Visit http://localhost:1313/ to see the site.

As you save edits to a page, the site will live-reload to show your changes.
