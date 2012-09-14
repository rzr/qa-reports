![QA Reports](http://qa-reports.meego.com/images/meego_logo_hover.png)

QA Reports is a test result reporting application originally developed for
[MeeGo](http://en.wikipedia.org/wiki/MeeGo). For basic features demonstration
see trailer at [YouTube](http://www.youtube.com/watch?v=sOUkwJT2RBo).

QA Reports is built with Ruby on Rails.

## Installation

*   Clone the repository
*   Edit `config/deploy.rb` and `config/deploy/production.rb`
*   Edit `config/bugzilla.yml` and `config/config.yml`
*   Run `cap production deploy:setup`
*   Run `cap production deploy`

For very thorough documentation see the instructions in [wiki](https://github.com/leonidas/qa-reports/wiki/Setting-up-the-production-environment).

## Migration Notes

*   11 September 2012: Added application configuration file `config/config.yml`. You
    will need to run `cap deploy:setup` again, or create a copy of the file to your
    servers `qa-reports/shared/config` folder before deploying.
*   10 September 2012: QA Reports was updated to use Ruby 1.9.3 and Rails 3.2.

## Configuration

*   `config/config.yml`: General application configuration
    * `allow_empty_files`: By default, QA Reports will not accept report files without any valid test cases. Set this to true to change that behavior.
    * `custom_results`: Test case results come from MeeGo project and are _Pass_, _Fail_, _N/A_, and _Measured_. Some user organizations may need additional results which can be configured here - e.g. `custom_results = ['Blocked', 'Pending']` makes QA Reports accept test cases with mentioned statuses. Note, that currently all custom statuses are handled as _N/A_ in the metrics.
*   `config/config.yml`: Bugzilla integration configuration
    * QA Reports can show bug information from Bugzilla. Bugzilla server settings are defined in this file.

When running `cap production deploy:setup` you will be prompted for the most important settings. There are a bunch of Ruby files in the `config` folder that can be adjusted as well if you wish. Notice however that no local changes apart from the abovementioned configuration files are effective on the server since Capistrano loads the software from Github upon deployment.

## License

QA Reports is licensed under the terms of the LGPL version 2.1
