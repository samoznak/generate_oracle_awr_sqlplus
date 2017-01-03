### Simple shell script to generate Oracle AWR using sqlplus
Prerequisities:

- bash
- sqlplus client
- getting Oracle DB instance ID and updating script variable eg. DBID=456213147
- SYS DBA or accoung having rights to run:

-- SQL exec plan dbms_xplan

GRANT select on sys.v_$session to &&role;

GRANT select on sys.v_$sql to &&role;

GRANT select on SYS.V_$SQL_PLAN to &&role;

GRANT select on sys.v_$sql_plan_statistics_all to &&role;

-- AWR report

GRANT SELECT ON SYS.V_$DATABASE TO &&role;

GRANT SELECT ON SYS.V_$INSTANCE TO &&role;

GRANT EXECUTE ON SYS.DBMS_WORKLOAD_REPOSITORY TO &&role;

GRANT SELECT ON SYS.DBA_HIST_DATABASE_INSTANCE TO &&role;

GRANT SELECT ON SYS.DBA_HIST_SNAPSHOT TO &&role;

GRANT ADVISOR TO &&role;

#### Usage

Usage: sh $0 -s "2017-01-02 10:00" -p 2 -U dbusername -P dbpassword -C "DB connection string" [-a] [-b]

-s date/time of beginning snapshot - format YYYY-MM-DD H24:MM

-p number of snapshots to generate

-U DB user account

-P DB password

-C DB connection string "dbserver.domain.com:1521/SERVICE_NAME"

-a generate multiple AWR reports. Scripts generates AWR report for each 30 minutes. This assumes that snapshots are generated each 30 minutes.

-b generate single AWR report from begin snap to end snap.

Example: sh $0 -s "2017-01-02 10:00" -p 2 -U dbaccount -P dbpassword -C "dbserver.domain.com:1521/SERVICE_NAME" -a -b

This example generates three AWR reports: 
2017-01-02 10:00 to 2017-01-02 10:30
2017-01-02 10:30 to 2017-01-02 11:00
2017-01-02 10:00 to 2017-01-02 11:00

##### TODO - feel free to contribute:

- Get DB instance ID
- Get DB instance number based on hostname - in case of RAC
- Test if DB user/password is correct. Exit if not 
- Enable other datetime formats
- Deal with UTC times
- Input checking
- Choice to generate html/text AWR report