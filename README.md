# README for schoolstatus-take-home

## Overview ##
This application displays a list of names and addresses. Selecting and clicking an individual name/address card will navigate you to a page that displays detailed information about the displayed location. Thus, this application may help one understand the needs of a community better. Please refer to the items below to execute this project locally.

## Prerequisites ##
* asdf version: >=0.14.0
* Ruby version: >=3.3.0
* Rails version: >=7.1.3.2

## Cloning the project ##
1. Run `git clone https://github.com/seb-lopez-331/schoolstatus-take-home.git`
2. Run `cd schoolstatus-take-home`

## Database initialization ##
1. If you do not currently own a copy of the `takehome.csv` file, please request a copy of it. This file contains the necessary data for this application to be usable.
2. Place the `takehome.csv` file inside the `db` directory.
3. Run `rails db:setup` on the command prompt.

## Running the project locally ##
1. Run `bin/dev` on the command line.
    (If you run into any errors, please run `asdf reshim` and try again)
2. Once the build finishes, navigate to your favorite browser (mine is Google Chrome) and type http://localhost:3000 into it.
