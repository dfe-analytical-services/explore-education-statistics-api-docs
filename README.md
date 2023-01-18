# Explore education statistics API documentation

This repository is used to generate the documentation website for the Explore education statistics API.
It is based on the GOV.UK [Technical Documentation Template](https://tdt-documentation.london.cloudapps.digital/)
for building 

## Getting started

The following pre-requisite dependencies are required to get started:

- [Node.js](https://nodejs.org/en/) v18+ (versions can be managed with [nvm](https://github.com/nvm-sh/nvm))
- [Ruby](https://www.ruby-lang.org/en/) v2.7.6 (versions can be managed with [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io/))

Once these have been installed, follow these steps:

1. Install the project's Ruby dependencies:

    ```shell
    bundle install
    ```
   
2. Start the development server:

    ```shell
    bundle exec middleman
    ```

    This will start the Middleman development server on [https://localhost:4567](https://localhost:4567).

3. Optional. To automatically refresh the browser upon code changes, install the [LiveReload browser extension](https://chrome.google.com/webstore/detail/livereload/jnihajbhpnppcggbcgedagnkighmdlei?hl=en).

For further guidance on how to develop this documentation, please visit the [Technical Documentation Template](https://tdt-documentation.london.cloudapps.digital/) website.

## Publishing changes

GitHub Actions automatically publishes changes merged into the main branch of this repository.

## Licence

Unless stated otherwise, the codebase is released under the [MIT License](LICENSE). This covers both 
the codebase and any sample code in the documentation.

The documentation is [© Crown copyright](http://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/copyright-and-re-use/crown-copyright/) 
and available under the terms of the [Open Government 3.0 licence](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
