CREATE OR REPLACE FUNCTION get_pushupgrades(varchar) 
   RETURNS TABLE (
      schemaName text,
      last_run timestamp,
      request_actual_time timestamp,
      request_status varchar,
      request_start_time timestamp,
      request_version_id varchar,
      request_sfid varchar,
      job_start_time timestamp,
      job_org_key varchar,
      job_status varchar,
      job_package_request_id varchar,
      job_sfid varchar,
      push_error_time timestamp,
      push_errortype varchar,
      push_error_title varchar,
      error_severity varchar,
      error_mesage varchar,
      error_details varchar,
      error_job_id varchar,
      error_sfid varchar,
      version_number text,
      package_release_state varchar,
      package_version_name varchar,
      package_version_time timestamp,
      package_version_id varchar,
      package_version_buildnumber int,
      package_version_isDeprecated bool,
      package_version_sfid varchar,
      instance_name varchar,
      installed_status varchar,
      orgname varchar,
      subscriber_time timestamp,
      orgstatus varchar,
      parentorg varchar,
      orgkey varchar,
      subscriber_version_id varchar,
      orgtype varchar,
      subscriber_sfid varchar,
      package_name varchar,
      package_time timestamp,
      namespaceprefix varchar,
      package_sfid varchar
) 
AS $$
BEGIN
  EXECUTE format('
          CREATE OR REPLACE VIEW pushupgrades AS
            SELECT
              ''%s'' as schemaName,
              TIMESTAMP ''%s'' AS last_run,
              %s.packagepushrequest.systemmodstamp as request_time,
              %s.packagepushrequest.status as request_status,
              %s.packagepushrequest.scheduledstarttime as request_start_time,
              %s.packagepushrequest.packageversionid as request_version_id,
              %s.packagepushrequest.sfid as request_sfid,
              %s.packagepushjob.systemmodstamp as job_start_time,
              %s.packagepushjob.subscriberorganizationkey as job_org_key,
              %s.packagepushjob.status as job_status,
              %s.packagepushjob.packagepushrequestid as job_package_request_id,
              %s.packagepushjob.sfid as job_sfid,
              %s.packagepusherror.systemmodstamp as push_error_time,
              %s.packagepusherror.errortype as push_errortype,
              %s.packagepusherror.errortitle as push_error_title,
              %s.packagepusherror.errorseverity as error_severity,
              %s.packagepusherror.errormessage as error_mesage,
              %s.packagepusherror.errordetails as error_details,
              %s.packagepusherror.packagepushjobid as error_job_id,
              %s.packagepusherror.sfid as error_sfid,
              CASE
                WHEN
                  %s.metadatapackageversion.patchversion > 0
                    THEN
                      CONCAT(%s.metadatapackageversion.majorversion,
                             %s,%s.metadatapackageversion.minorversion,
                             %s,%s.metadatapackageversion.patchversion)
                ELSE
                    CONCAT(%s.metadatapackageversion.majorversion,
                          %s,%s.metadatapackageversion.minorversion)
              END AS version_number,
              %s.metadatapackageversion.releasestate as package_release_state,
              %s.metadatapackageversion.name as package_version_name,
              %s.metadatapackageversion.systemmodstamp as package_version_time,
              -- %s.metadatapackageversion.patchversion as package_patch_version,
              %s.metadatapackageversion.metadatapackageid as package_version_id,
              %s.metadatapackageversion.buildnumber as package_version_buildnumber,
              %s.metadatapackageversion.isdeprecated as package_version_isDeprecated,
              %s.metadatapackageversion.sfid as package_version_sfid,
              %s.packagesubscriber.instancename as instance_name,
              %s.packagesubscriber.installedstatus as installed_status,
              %s.packagesubscriber.orgname as orgname,
              %s.packagesubscriber.systemmodstamp as subscriber_time,
              %s.packagesubscriber.orgstatus as orgstatus,
              %s.packagesubscriber.parentorg as parentorg,
              %s.packagesubscriber.orgkey as orgkey,
              %s.packagesubscriber.metadatapackageversionid as subscriber_version_id,
              %s.packagesubscriber.orgtype as orgtype,
              %s.packagesubscriber.sfid as subscriber_sfid,
              %s.metadatapackage.name as package_name,
              %s.metadatapackage.systemmodstamp as package_time,
              %s.metadatapackage.namespaceprefix as namespaceprefix,
              %s.metadatapackage.sfid as package_sfid
            FROM %s.packagepushrequest
            RIGHT OUTER JOIN %s.packagepushjob
            ON %s.packagepushrequest.sfid = %s.packagepushjob.packagepushrequestid
            FULL OUTER JOIN %s.packagepusherror 
            ON %s.packagepushjob.sfid = %s.packagepusherror.packagepushjobid
            FULL OUTER JOIN %s.metadatapackageversion
            ON %s.metadatapackageversion.sfid = %s.packagepushrequest.packageversionid
            FULL OUTER JOIN %s.packagesubscriber
            ON %s.packagepushjob.subscriberorganizationkey = %s.packagesubscriber.orgkey
            FULL OUTER JOIN %s.metadatapackage
            ON %s.metadatapackageversion.metadatapackageid = %s.metadatapackage.sfid            
            ', $1,NOW(),$1,$1,$1,$1,$1,$1,$1,$1,$1,$1, $1,$1,$1,$1,$1,$1,$1,$1,$1,$1,'''.''',$1,'''.''',$1,$1,
               '''.''',$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,
               $1,$1,$1,$1,$1,$1,$1, $1,$1,$1,$1,$1, $1,$1,$1,$1,$1
             );
RETURN QUERY
SELECT * FROM pushupgrades;
END; $$ 
LANGUAGE 'plpgsql';

