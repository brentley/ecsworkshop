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

#### Install node packages:
`npm install`

#### Run Hugo locally:
`npm run server`

#### View Hugo locally:
Visit http://localhost:1313/ to see the site.

#### Making Edits:
As you save edits to a page, the site will live-reload to show your changes.

#### Auto Deploy:
Any commits to master will auto build and deploy in a couple of minutes. You can see the currently
deployed hash at the bottom of the menu panel.

note: shift-reload may be necessary in your browser to reflect the latest changes.

Check out the commands in `buildspec.yml` to see the build/deploy process
