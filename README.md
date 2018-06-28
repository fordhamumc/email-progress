# GiveCampus Campaign Status in CSS
Uses CSS selectors to scape data from a GiveCampus.org fundraising page and generate a css document that can be used to dynamically update an email with the latest stats. It also generates fallback images for browsers that do not support external stylesheets or pseudo-selectors.

[View an example email.](https://mailchi.mp/fordham/live-content-example)

## Getting Started
These instructions are for people who would like to edit a local version of the project. If you would like to deploy right to Heroku, you can skip to the deployment section.

### Requirements
* [Ruby](https://www.ruby-lang.org/) >= 2.x
* [Bundler](https://bundler.io/) >= 1.x
* [Redis](https://redis.io/) >= 4.x

### Installation
After you clone the repo, install the required gems.

```
bundle install
```

Create the environment file.

```
cp .env.example .env
```

Open the `.env` file and setup your variables

## Start the application

Start the redis server

```
redis-server
```

Start the application

```
bundle exec foreman start
```

Visit [http://localhost:5000](http://localhost:5000)


## Deployment
Click the "Deploy to Heroku" button and follow the steps on the next screen to create 
your own version of this application.

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)


## Environment Variables

* `GIVECAMPUS_URL` The page you will be scraping.
* `DONORS_PATH` Path to the donor count. (Accepts any valid css) 
* `GOAL_PATH` Path to the donor goal. (Accepts any valid css) 
* `RAISED_PATH` Path to the amount raised. (Accepts any valid css) 
* `LEADERBOARD_PATH` Path to the leaderboard tables. (Accepts any valid css) 
* `LEADERBOARDITEM_CLASS` The title of the class leaderboard. 
* `LEADERBOARDITEM_SCHOLARSHIP` The title of the scholarship leaderboard. 
* `CHALLENGE_GOAL` The goal for a specific challenge.
* `CHALLENGE_START` The starting point for the challenge.
* `SCREENSHOT_URL` The url to screenshot. Defaults to http://localhost:5000
* `AWS_ACCESS_KEY_ID` Amazon Web Services access key.
* `AWS_SECRET_ACCESS_KEY` Amazon Web Services secret access key.
* `AWS_REGION` Amazon Web Services S3 region.
* `AWS_BUCKET` Amazon Web Services S3 bucket.


## Using Dynamic content In An Email

Include your generated stylesheet but hide it from outlook. Then copy the below snippets into the body of your email.

```html
<!--[if !mso]><!--><link href="https://s3.amazonaws.com/<<YOUR_S3_BUCKET>>/progress.css" rel="stylesheet"><!--<![endif]-->
```

### Progress Bar

```html
<!--[if !mso]><!-->
  <div class="progress-container" id="challenge-bar">
    <div class="progress-percent"></div>
    <div class="progress-bar">
      <div class="progress"></div>
      <div class="progress-count"></div>
    </div>
  </div>
<!--<![endif]-->
<img src="https://s3.amazonaws.com/<<YOUR_S3_BUCKET>>/challenge-bar.png" alt="Don't forget an alt tag" class="webkit-hide">
```

### Progress Stats

```html
<!--[if !mso]><!-->
<div id="progress-stats" class="progress-stats">
  <div class="total-goal amount"></div>
  <div class="total-donors amount"></div>
  <div class="total-dollars amount"></div>
</div>
<!--<![endif]-->
<img src="https://s3.amazonaws.com/<<YOUR_S3_BUCKET>>/stats.png" alt="Don't forget an alt tag" class="webkit-hide">
```

### Class Participation Table

```html
<!--[if !mso]><!-->
<table id="participation-class" width="100%" cellpadding="0" cellspacing="0" class="progress-table">
  <thead>
    <tr>
      <th class="name"></th>
      <th class="donors"></th>
      <th class="dollars"></th>
    </tr>
  </thead>
  <tbody>
    <tr id="lb-class-1">
      <td class="name"></td>
      <td class="donors"></td>
      <td class="dollars"></td>
    </tr>
    <tr id="lb-class-2" class="alt">
      <td class="name"></td>
      <td class="donors"></td>
      <td class="dollars"></td>
    </tr>
    <tr id="lb-class-3">
      <td class="name"></td>
      <td class="donors"></td>
      <td class="dollars"></td>
    </tr>
    <tr id="lb-class-4" class="alt">
      <td class="name"></td>
      <td class="donors"></td>
      <td class="dollars"></td>
    </tr>
    <tr id="lb-class-5">
      <td class="name"></td>
      <td class="donors"></td>
      <td class="dollars"></td>
    </tr>
  </tbody>
</table>
<!--<![endif]-->
<img src="https://s3.amazonaws.com/<<YOUR_S3_BUCKET>>/top-years.png" alt="Don't forget an alt tag" class="webkit-hide">
```

### Top Funding Areas

```html
<!--[if !mso]><!-->
<table id="participation-areas" width="100%" cellpadding="0" cellspacing="0" class="progress-table">
  <thead>
    <tr>
      <th class="name"></th>
      <th class="donors"></th>
      <th class="dollars"></th>
    </tr>
  </thead>
  <tbody>
    <tr id="lb-support-1">
      <td class="name"></td>
      <td class="donors"></td>
      <td class="dollars"></td>
    </tr>
    <tr id="lb-support-2" class="alt">
      <td class="name"></td>
      <td class="donors"></td>
      <td class="dollars"></td>
    </tr>
    <tr id="lb-support-3">
      <td class="name"></td>
      <td class="donors"></td>
      <td class="dollars"></td>
    </tr>
    <tr id="lb-support-4" class="alt">
      <td class="name"></td>
      <td class="donors"></td>
      <td class="dollars"></td>
    </tr>
    <tr id="lb-support-5">
      <td class="name"></td>
      <td class="donors"></td>
      <td class="dollars"></td>
    </tr>
  </tbody>
</table>
<!--<![endif]-->
<img src="https://s3.amazonaws.com/<<YOUR_S3_BUCKET>>/top-areas.png" alt="Don't forget an alt tag" class="webkit-hide">
```

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Acknowledgments
This project was inspired by [Kevin Mandeville's](https://www.kevinmandeville.com/) article ["How to Code A Live Dynamic Twitter Feed in HTML Email"](https://litmus.com/blog/how-to-code-a-live-dynamic-twitter-feed-in-html-email)