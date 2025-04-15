# The Problem
I found multiple times that I had problems with [Home Assistant](https://www.home-assistant.io/) (HA) Automations, but did not find a way inside HA to flag or find the errors.

# My Solution
- I was able to find the traces file in my HA Raspberry Pi in ```/mnt/data/supervisor/homeassistant/.storage/trace.saved_traces```.
  - It should be noted that by default only 5 traces per automation are stored (configurable in the automation itself). Beyond the default (or the configured new max), the traces are rolled.
- The traces file is a big JSON document.
- Home Assistant OS does not appear to have cron, therefore, any cron jobs and scripts for HA, I have running on an external system with key-based SSH access. I have this script running hourly with the knowledge that I don't have automations running frequently.
- I wrote a script that will download the traces file and look for "bad executions", collect some additional information and send me an email.
  - I'm using the [ssmtp project](https://medium.com/@aleksej.gudkov/setting-up-ssmtp-with-gmail-for-sending-emails-29b0ea84a1b5), which makes it relatively easy to use GMail as the email mechanism from linux machines.

# Usage
- The script makes some assumptions
  - That the system running the script has SSH key access to the system running HA
  - That the system running the script has ssmtp configured and working (outside the scope of this article)
- Modify the script so that the TO variable is where you want the emails to go to
- Modify the script so that the FROM variable is what ssmtp is expecting to use as the FROM address
- I have my script running every hour, via cron, at the 2 minute mark
```02 * * * * /home/ubuntu/scripts/ha-automation-errors.sh```

# Results
The email that comes through includes a "Subject: Hostname HA Errors"
And the contents of the email will look similar to (the script will not actually notify on failed_conditions, I just used that as a test condition):

```
          "script_execution": "failed_conditions",
                      "last_triggered": "2025-04-09T00:59:00.720714+00:00",
                      "friendly_name": "test-automation"
```
