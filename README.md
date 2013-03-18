![QA Reports](http://qa-reports.meego.com/images/meego_logo_hover.png)

QA Reports is a web based test result reporting application originally developed for
[MeeGo](http://en.wikipedia.org/wiki/MeeGo). For basic features demonstration
see trailer at [YouTube](http://www.youtube.com/watch?v=sOUkwJT2RBo). User
guide and other detailed documentation is available in [wiki](https://github.com/leonidas/qa-reports/wiki).

Test results can be uploaded either using [web UI](https://github.com/leonidas/qa-reports/wiki/User-guide#wiki-import)
or [import API](https://github.com/leonidas/qa-reports/wiki/API-Documentation#wiki-import).
Supported [result file formats](https://github.com/leonidas/qa-reports/wiki/XML-Formats)
are MeeGo test-definition, Google Test Framework, and xUnit XML formats.

QA Reports is built with Ruby on Rails.

## Installation

*   Clone the repository
*   Edit `config/deploy.rb` and `config/deploy/production.rb`
*   Edit `config/bugzilla.yml` and `config/config.yml`
*   Run `cap production deploy:setup`
*   Run `cap production deploy`

For very thorough documentation see the instructions in [wiki](https://github.com/leonidas/qa-reports/wiki/Setting-up-the-production-environment).

## Migration Notes

*   11 March 2013: Ruby 2.0 compatible.
*   11 September 2012: Added application configuration file `config/config.yml`. You
    will need to run `cap deploy:setup` again, or create a copy of the file to your
    servers `qa-reports/shared/config` folder before deploying.
*   10 September 2012: QA Reports was updated to use Ruby 1.9.3 and Rails 3.2.

## Configuration

*   `config/config.yml`: General application configuration
    * Application configuration is aimed for enabling customization while keeping your fork compatible with the upstream version.
*   `config/config.yml`: Bugzilla integration configuration
    * QA Reports can show bug information from Bugzilla. Bugzilla server settings are defined in this file.
*   `config/deploy.rb` and `config/deploy/production.rb`: Deployment settings
*   `config/environment.rb`: Environment specific configuration, e.g. email settings

When running `cap production deploy:setup` you will be prompted for the most important settings. There are a bunch of Ruby files in the `config` folder that can be adjusted as well if you wish. Notice however that no local changes apart from the ones `deploy:setup` asks are effective on the server since Capistrano loads the software from Github upon deployment.

## License

QA Reports is licensed under the terms of the LGPL version 2.1
