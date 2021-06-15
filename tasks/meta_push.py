import os
import psycopg2
from psycopg2 import sql
from cumulusci.tasks.salesforce import BaseSalesforceApiTask

# from cumulusci.tasks.salesforce import BaseSalesforceToolingApiTask


class SyncPushErrors(BaseSalesforceApiTask):
    """
    This class was created to support the collection of package push errors to a postgresql
    heroku database. To achieve this a task named metapush_package_errors was created which collects the
    push package errors from its connected org and updates them to a view created in a remote
    database to track each orgsrespective package's errors.
    """

    task_options = {
        "offset": {"description": "Offset to use in SOQL query of PackagePushError"}
    }

    def _init_options(self, kwargs):
        super(SyncPushErrors, self)._init_options(kwargs)
        # Set the namespace option to the value from cumulusci.yml if not already set
        # if "namespace" not in self.options:
        self.options["namespace"] = self.project_config.project__package__namespace

    def _run_task(self):
        # Get heroku postgres service
        service = self.project_config.keychain.get_service("metapush_postgres")
        DATABASE_URL = service.db_url

        conn = psycopg2.connect(DATABASE_URL, sslmode="require")
        # Query PackagePushErrors

        # Open a cursor to perform database operations
        cur = conn.cursor()
        # Execute a command that gets the last time this report was run
        cur.execute("SELECT MAX(last_run) from pushupgrades;")
        last_run = cur.fetchone()[0].strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "+0000"
        self.job_query = f"SELECT Id, PackagePushJobId, ErrorMessage, ErrorDetails, ErrorTitle, ErrorSeverity, ErrorType, SystemModstamp FROM packagePushError WHERE SystemModstamp > 2019-11-01T07:59:43.036+0000 LIMIT 2"  # {last_run}"
        # self.job_query = f"SELECT Id, PackagePushJobId, ErrorMessage, ErrorDetails, ErrorTitle, ErrorSeverity, ErrorType, SystemModstamp FROM packagePushError WHERE SystemModstamp > {last_run}"

        formatted_query = self.job_query.format(**self.options)
        self.logger.debug("Running query for job errors: " + formatted_query)
        result = self.sf.query(formatted_query)
        job_records = result["records"]
        self.logger.debug(
            "Query is complete: {done}. Found {n} results.".format(
                done=result["done"], n=result["totalSize"]
            )
        )
        if not result["totalSize"]:
            self.logger.info("No errors found.")
            return

        offset = cur.execute(
            sql.SQL("SELECT COUNT(*) FROM {}.packagepusherror;").format(
                sql.Identifier(self.options["schema"])
            )
        )

        offset = cur.fetchone()[0]
        self.logger.info("OFFSET: ", offset)
        id = 0 + offset + 1
        for records in job_records:
            row = {}
            for _, (k, v) in enumerate(records.items()):
                # skipping unwanted attribute key values storing all others to be upserted
                if k.lower() != "attributes":
                    row[k] = v
            self.logger.info(row)
            self.logger.info("")
            cur.execute(
                sql.SQL(
                    "INSERT INTO {}.packagepusherror (systemmodstamp,errortype,errortitle,errorseverity,errormessage,errordetails,packagepushjobid,sfid,id,_hc_lastop,_hc_err) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s,%s,%s) ON CONFLICT DO NOTHING;"
                ).format(sql.Identifier(self.options["schema"])),
                [
                    row["SystemModstamp"],
                    row["ErrorType"],
                    row["ErrorTitle"],
                    row["ErrorSeverity"],
                    row["ErrorMessage"],
                    row["ErrorDetails"],
                    row["PackagePushJobId"],
                    row["Id"],
                    id,
                    "NULL",
                    "NULL",
                ],
            )
            id += 1
            conn.commit()
        cur.execute(
            sql.SQL("SELECT get_pushupgrades('{}')").format(
                sql.Identifier(self.options["schema"])
            )
        )
        # shows results of built in function see pushupgrades.sql
        push_upgrades = cur.fetchall()[0]
        self.logger.info(push_upgrades)
        # Close communication with the database
        cur.close()
        conn.close()
