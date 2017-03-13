# GiveCampus Campaign Status in CSS
Uses CSS selectors to scape data from a GiveCampus.org fundraising page, although it could 
be used on other sites as well.

## Deploy A Copy
Click the "Deploy to Heroku" button and follow the steps on the next screen to create 
your own version of this application. You'll need a URL to scrape and CSS paths to the data.

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

## Local Development

### Requirements
* Git
* Ruby
* Bundler

### Setup
1. Clone This Repo: `git clone https://github.com/fordhamumc/email-progress.git`
2. Install Dependencies: `cd email-progress && bundle install`
3. Create Environment File: `cp .env.example .env` 
4. Enter the URL to Scape in `.env`
5. Enter the CSS Paths to the Data to Scrape `.env`
6. Run `bundle exec foreman start`
7. Visit [http://localhost:5000/progress.css](http://localhost:5000/progress.css)
