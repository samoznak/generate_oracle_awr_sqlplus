#!/bin/sh
# Simple shell script to generate Oracle AWR using sqlplus
# Read get_help

# shellcheck disable=SC1091
. ~/.bash_profile

# Oracle database ID
# TODO - automatically get DBID
DBID=456213147
# TODO - being able to select hostname when calling script (only applies for RAC)
INSTANCE_NUMBER=1
# sqlplus binary path
SQLPLUS=/oracle/product/client/11.2.0.3/bin/sqlplus
# init variables
a=false
b=false

# Need to add two mins to be able to select snap_id by begin_snap_time
get_begin_snap_endtime() {
begin_snap_time_end=$( date --date="${begin_snap_time}" +%s )
begin_snap_time_end=$((begin_snap_time_end+120))
begin_snap_time_end=$( date -d@${begin_snap_time_end} '+%Y-%m-%d %H:%M')
}

# Select snap_id from Oracle database based on BEGIN_INTERVAL_TIME
get_begin_snap() {
#DEBUG only
#echo "get_begin_snap"
#DEBUG only
#echo "${SQLPLUS} -S ${DBUSER}/${DBPASSWD}@${DBCONNSTRING}"
begin_snap_id=$(
${SQLPLUS} -S "${DBUSER}"/"${DBPASSWD}"@"${DBCONNSTRING}" <<EOF
SET TERMOUT OFF PAGESIZE 0 HEADING OFF LINESIZE 1000 TRIMSPOOL ON TRIMOUT ON TAB OFF FEEDBACK OFF;
select snap_id from DBA_HIST_SNAPSHOT where
BEGIN_INTERVAL_TIME between
to_date('${begin_snap_time}', 'YYYY-MM-DD HH24:MI')
and to_date('${begin_snap_time_end}', 'YYYY-MM-DD HH24:MI')
and INSTANCE_NUMBER=${INSTANCE_NUMBER};
EOF
)
#DEBUG only
#echo "${SQLPLUS} -S ${DBUSER}/${DBPASSWD}@${DBCONNSTRING}
#SET TERMOUT OFF PAGESIZE 0 HEADING OFF LINESIZE 1000 TRIMSPOOL ON TRIMOUT ON TAB OFF FEEDBACK OFF;
#select snap_id from DBA_HIST_SNAPSHOT where
#BEGIN_INTERVAL_TIME between
#to_date('${begin_snap_time}', 'YYYY-MM-DD HH24:MI')
#and to_date('${begin_snap_time_end}', 'YYYY-MM-DD HH24:MI')
#and INSTANCE_NUMBER=${INSTANCE_NUMBER};"

#parse output by echoing
begin_snap_id=$(echo ${begin_snap_id})

#For some reason I had to substract 1 for my DB. Correct snap_id wasn't returned
begin_snap_id=$((begin_snap_id-1))

#DEBUG only
#echo ${begin_snap_id}
}

# 
get_end_snap() {
echo "get_end_snap"
end_snap_id=$((begin_snap_id+end_snap))
}

# Calling AWR generation for begin_snap_id and end_snap_id - whole timespan
generate_awr() {
if ${b}; then
${SQLPLUS} -S "${DBUSER}"/"${DBPASSWD}"@"${DBCONNSTRING}" <<EOF
SET TERMOUT OFF PAGESIZE 0 HEADING OFF LINESIZE 1000 TRIMSPOOL ON TRIMOUT ON TAB OFF FEEDBACK OFF;
SPOOL AWR_report_${begin_snap_id}_${end_snap_id}.html
select output from table(dbms_workload_repository.awr_report_html (${DBID}, ${INSTANCE_NUMBER}, ${begin_snap_id}, ${end_snap_id}));
spool off;
EOF
  else
  echo "Skipping AWR generation"
fi
}

# Calling AWR generation for begin_snap_id and end_snap_id - 
generate_awr_30() {
if ${a}; then
for (( i = begin_snap_id; i < end_snap_id; i++ )); do
begin_snap_id_rpt=${i}
echo ${begin_snap_id_rpt}
end_snap_id_rpt=$((begin_snap_id_rpt+1))
echo ${end_snap_id_rpt}
${SQLPLUS} -S "${DBUSER}"/"${DBPASSWD}"@"${DBCONNSTRING}" <<EOF
SET TERMOUT OFF PAGESIZE 0 HEADING OFF LINESIZE 1000 TRIMSPOOL ON TRIMOUT ON TAB OFF FEEDBACK OFF;
SPOOL AWR_report_${begin_snap_id_rpt}_${end_snap_id_rpt}.html
select output from table(dbms_workload_repository.awr_report_html (${DBID}, ${INSTANCE_NUMBER}, ${begin_snap_id_rpt}, ${end_snap_id_rpt}));
spool off;
EOF
done
  else
  echo "Skipping AWR generation per 30 mins"
fi
}

run() {
echo "begin_snap_time: ${begin_snap_time}"
get_begin_snap_endtime
echo "begin_snap_time_end: ${begin_snap_time_end}"
get_begin_snap
echo "begin_snap_id: ${begin_snap_id}"
get_end_snap
echo "end_snap: ${end_snap_id}"
generate_awr_30
generate_awr
}

# Help output
get_help() {
echo "!!! WRONG DB PASSWORD CAN LOCK YOUR DB ACCOUNT !!!
Usage: sh $0 -s \"2017-01-02 10:00\" -p 2 -U dbusername -P dbpassword -C \"DB connection string\" [-a] [-b]
-s date/time of beginning snapshot - format YYYY-MM-DD H24:MM
-p number of snapshots to generate
-U DB user account
-P DB password
-C DB connection string \"dbserver.domain.com:1521/SERVICE_NAME\"
-a generate multiple AWR report. Scripts generates AWR report for each 30 minutes.
-b generate single AWR report from begin snap to end snap.
Example: sh $0 -s \"2017-01-02 10:00\" -p 2 -U dbusername -P dbpassword -C \"dbserver.domain.com:1521/SERVICE_NAME\" -a
This example generates three AWR reports: 
2017-01-02 10:00 to 2017-01-02 10:30
2017-01-02 10:30 to 2017-01-02 11:00
2017-01-02 10:00 to 2017-01-02 11:00

TODO:
- Get DB instance ID
- Get DB instance number based on hostname - in case of RAC
- Test if DB user/password is correct. Exit if not 
- Enable other datetime formats
- Deal with UTC times
- Input checking
- Choice to generate html/text AWR report
"
exit
}

while getopts "s:p:U:P:C:abh" opt; do
  case $opt in
    s)
      begin_snap_time=${OPTARG}
      ;;
    p)
      end_snap=${OPTARG}
      ;;
    a)
      a=true
      ;;
    b)
      b=true
      ;;
    U)
      DBUSER=${OPTARG}
      ;;
    P)
      DBPASSWD=${OPTARG}
      ;;
    C)
      DBCONNSTRING=${OPTARG}
      ;;
    h)
      get_help
      ;;
    *)
      get_help
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${begin_snap_time}" ] || [ -z "${end_snap}" ] || [ -z "${DBUSER}" ] || [ -z "${DBPASSWD}" ] || [ -z "${DBCONNSTRING}" ]; then
    get_help
fi

run
