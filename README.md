# QA Reports

Test reporting application originally developed for MeeGo QA teams. See trailer at
[YouTube](http://www.youtube.com/watch?v=sOUkwJT2RBo)

See up-to-date documentation at [wiki](https://github.com/leonidas/qa-reports/wiki)

## Migration Notes

*   11 September 2012: Added application configuration file `config/config.yml`. You
    will need to run `cap deploy:setup` again, or create a copy of the file to your
    servers `qa-reports/shared/config` folder before deploying.
*   10 September 2012: QA Reports was updated to use Ruby 1.9.3 and Rails 3.2.