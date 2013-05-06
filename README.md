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
*   Edit `config/external.services.yml` and `config/config.yml`
*   Run `cap production deploy:setup`
*   Run `cap production deploy:migrations`

For very thorough documentation see the instructions in [wiki](https://github.com/leonidas/qa-reports/wiki/Setting-up-the-production-environment).

## Migration Notes

*   06 May 2013: Added Gerrit integration (link by change ID the same way as Bugzilla)
*   29 April 2013: Not compatible with old installations of [QA Dashboard](https://github.com/leonidas/qa-dashboard). If you have been using QA Dashboard you will need to update it as well.
*   02 April 2013: New external configuration and service support taken in use. This will replace the old `bugzilla.yml` configuration file. Upgrading is not mandatory, `bugzilla.yml` will still work if it exist. See [wiki](https://github.com/leonidas/qa-reports/wiki/External-Services) for more information.
*   26 March 2013: [Asset Pipeline](http://guides.rubyonrails.org/asset_pipeline.html) taken in use.
    * If you are using a custom stylesheet you should combine it to the main stylesheet (not required though). See [wiki](https://github.com/leonidas/qa-reports/wiki/Customization) for more information.
    * With asset pipeline you can enable asset caching and can use nginx's `gzip static`. See [wiki](https://github.com/leonidas/qa-reports/wiki/Setting-up-the-production-environment#wiki-nginx) for an example.
*   11 March 2013: Ruby 2.0 compatible.
*   11 September 2012: Added application configuration file `config/config.yml`. You
    will need to run `cap deploy:setup` again, or create a copy of the file to your
    servers `qa-reports/shared/config` folder before deploying.
*   10 September 2012: QA Reports was updated to use Ruby 1.9.3 and Rails 3.2.

## Configuration

*   `config/config.yml`: General application configuration
    * Application configuration is aimed for enabling customization while keeping your fork compatible with the upstream version.
*   `config/external.services.yml`: External services integration configuration
    * QA Reports can showinformation from Bugzilla and Gerrit, and create links to other services. Settings are defined in this file. See [wiki](https://github.com/leonidas/qa-reports/wiki/External-Services) for more information.
*   `config/deploy.rb` and `config/deploy/production.rb`: Deployment settings
*   `config/environments/production.rb`: Environment specific configuration, e.g. email settings

When running `cap production deploy:setup` you will be prompted for the most important settings. There are a bunch of Ruby files in the `config` folder that can be adjusted as well if you wish. Notice however that no local changes apart from the ones `deploy:setup` asks are effective on the server since Capistrano loads the software from Github upon deployment.

## License

QA Reports is licensed under the terms of the LGPL version 2.1
