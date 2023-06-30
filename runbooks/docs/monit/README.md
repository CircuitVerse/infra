# Monitoring Server using Monit

[Monit](https://mmonit.com/monit/) is a small Open Source utility for managing and monitoring Unix systems.
Monit conducts automatic maintenance and repair and can execute meaningful causal actions in error situations.

**Table of Contents**

- [Monit Service]()
  - [Configuration](#Configuration)
  - [Alerting](#mail-alerts)
  - [Summary](#Summary)

# Configuration

Configuration files are present in the conf-enabled folder.

Monit monitors following services on our Server:

- Postgresql Server
- Redis Server
- Caddy Webserver
- Procodile

# Alerting

Alerts are sent using SMTP, to the mail address mentioned in the [monitrc](/link-to-monitrc) file.

# Summary

