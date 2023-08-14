# Monitoring Server using Monit

[Monit](https://mmonit.com/monit/) is a small Open Source utility for managing and monitoring Unix systems.
Monit conducts automatic maintenance and repair and can execute meaningful causal actions in error situations.

## Configuration

1. Install Monit

```bash
sudo apt-get install Monit
brew install monit
```

Monit monitors following services on our Server:

- Postgresql 
- Redis
- Caddy Webserver
- Procodile

Configuration files for each service is present in the [conf-enabled](./conf-enabled) folder.

2. After placing all the monit configuration files and editing the monitrc file, restart monit daemon. 

```bash
sudo monit reload
sudo systemctl restart monit
brew services restart monit
```

Monit daemon checks for all these services 2 mins(by default), this can be changed in [monitrc](./monitrc)
`set daemon 120`

Monit dashboard can be accessed at [http://localhost:2812](http://localhost:2812)

```bash
set httpd port 2812 and
     allow 0.0.0.0/0        # allow localhost to connect to the server and
     allow 34.208.62.213    # Change this to HOST_IP of server 
	 
     # Change username:password
     allow admin:monit      # require user 'admin' with password 'monit'
```

## Alerting

Alerts are sent using SMTP in the [monitrc](/monitrc) file.
In order to use Gmail SMTP mail server you must have [2FA enabled](https://support.google.com/accounts/answer/185839?hl=en&co=GENIE.Platform%3DAndroid) for the Google Account.

Next step is to create to create a new google [app password](https://support.google.com/mail/answer/185833?hl=en).

On creating this replace your email address and the 16 digit password obtained after creating the Gmail SMTP app and add it to the [monitrc](./monitrc) file as shown below:

```bash
# Mail Alerts
set mailserver smtp.gmail.com port 587
     username "circuitverse" password "16digitsmtpswd" # for email address circuitverse@gmail.com
     using tls
```
