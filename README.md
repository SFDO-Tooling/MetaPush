# MetaPush

MetaPush was designed to deliver live time packagepusherrors to a centralized heroku postgresql database.
In addition to this task being created for the cli to push the errors to postgres, a backend process
also occurs to join the data tables together to allow for meaningful error messages for the user, which
is intended to be the CCE team however this is available to whoever decides to use this task.


## Development

To run MetaPush you must complete the following steps:

1. [Set up CumulusCI](https://cumulusci.readthedocs.io/en/latest/tutorial.html)
2. Run `pip install -r requirements.txt` to install the necessary package dependencies.
3. Run `cci org connect <name of org>` and connect to your packaging org.
4. To configure your system please visit the following document to get the db_url for the [Heroku Postgres server](https://salesforce.quip.com/iMfNAdOUR4M5). For access to the quip document please contact Salesforce.org's Release Engineering department. 
5. Run `cci service connect metapush_postgres` from your project's root directory, use the DB_URL from step 4 when prompted.
6. In your cumulusci.yml file under tasks -> meta_push -> options -> schema set your value to your appropriate org schema name (e.g. abacus).
7. Run `cci task run metapush_package_errors --org <name of org>` to push your package push errors to the postgresql database.