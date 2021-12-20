# JamfPro-multitenant-log4j-patch

Patching script for Jamf Pro manual installation on a multi-tenant, Red Hat Enterprise Linux installation.

## Usage

- Copy to the Jamf Pro Server (must be run on each node of a cluster).
- Run `bash fix-log4j.sh`.
- Press `Y` to confirm that you want to stop tomcat8 and replace the log4j files that are shown in the output.
