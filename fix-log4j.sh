#!/bin/bash

: <<DOC
https://docs.jamf.com/technical-articles/Mitigating_the_Apache_Log4j_2_Vulnerability.html

deletes:
/usr/share/tomcat8/webapps/*/WEB-INF/lib/log4j-1.2-api-2.13.3.jar
/usr/share/tomcat8/webapps/*/WEB-INF/lib/log4j-api-2.13.3.jar
/usr/share/tomcat8/webapps/*/WEB-INF/lib/log4j-core-2.13.3.jar
/usr/share/tomcat8/webapps/*/WEB-INF/lib/log4j-slf4j-impl-2.13.3.jar

creates:
/usr/share/tomcat8/webapps/*/WEB-INF/lib/log4j-1.2-api-2.17.0.jar
/usr/share/tomcat8/webapps/*/WEB-INF/lib/log4j-api-2.17.0.jar
/usr/share/tomcat8/webapps/*/WEB-INF/lib/log4j-core-2.17.0.jar
/usr/share/tomcat8/webapps/*/WEB-INF/lib/log4j-slf4j-impl-2.17.0.jar
DOC

# old_jars=( log4j-1.2-api-2.13.3.jar log4j-api-2.13.3.jar log4j-core-2.13.3.jar log4j-slf4j-impl-2.13.3.jar )
new_jars=( log4j-1.2-api-2.17.0.jar log4j-api-2.17.0.jar log4j-core-2.17.0.jar log4j-slf4j-impl-2.17.0.jar )

new_jar_source="/root/log4j-vuln-2021-12-18/apache-log4j-2.17.0-bin"
webapps_dir="/usr/share/tomcat8/webapps"
backup_dir="/root/log4j-vuln-2021-12-18/backups"

mkdir -p "/root/log4j-vuln-2021-12-18"
cd "/root/log4j-vuln-2021-12-18" || exit
if [[ ! -d apache-log4j-2.17.0-bin ]]; then
    curl https://dlcdn.apache.org/logging/log4j/2.17.0/apache-log4j-2.17.0-bin.zip -o apache-log4j-2.17.0-bin.zip
    unzip apache-log4j-2.17.0-bin.zip
fi

mkdir -p "$backup_dir"

# build a list of instances
dir_list=()
while IFS= read -d $'\0' -r dir ; do
    dir_list=("${dir_list[@]}" "$dir")
done < <(find "$webapps_dir/" -mindepth 1 -maxdepth 1 -type d ! -name "*manager" -print0)

echo "This script will delete the following files (backups will be made):"
for instance in "${dir_list[@]}"; do
    find "$instance/WEB-INF/lib" -name "log4j-*" -type f
done

echo
read -r -p "WARNING! Are you sure? (Y/N) : " are_you_sure
case "$are_you_sure" in
    Y|y)
        echo "Confirmed"
    ;;
    *)
        echo "Not confirmed - exiting"
        exit
    ;;
esac

echo
echo "Stopping tomcat8"
systemctl stop tomcat8

# remove the old jar files
echo
echo "Moving old jar files to backup directory $backup_dir"
for instance in "${dir_list[@]}"; do
    find "$instance/WEB-INF/lib" -name "log4j-*" -type f -exec mv {} "$backup_dir/" \;
done

# copy in the new jar files
echo
echo "Copying in the new jar files"
for instance in "${dir_list[@]}"; do
    for jar_file in "${new_jars[@]}"; do
        if cp "$new_jar_source/$jar_file" "$instance/WEB-INF/lib/" ; then
            echo "Copied $jar_file to $instance"
        else
            echo "Failed to copy $jar_file to $instance"
        fi
    done
    # reset permissions
    echo
    echo "Resetting file ownership to tomcat8:tomcat8"
    chown tomcat8:tomcat8 "$instance/WEB-INF/lib/"log4j-*
done

echo
echo "Done. Starting tomcat8"

systemctl start tomcat8

echo

systemctl status tomcat8

echo
echo "Script complete"