# voipbl.sh
Import VOIPBL blacklisted IPs into Fail2Ban

# Working importer for IPTables
The VOIPBL.org site offers scripts to import their list into IPTables, but there are errors that prevent them from working correctly. This script builds upon the work found at https://github.com/WyoMurf/voipBL-CentOS6, but that repository is incomplete. He uses an GO based program to convert the list into an ipset backup, which can be very rapidly restored. However, he doesn't include that program in the repo.

# Reasonably fast
While it isn't as fast as [WyoMurph's](https://github.com/WyoMurf) reported 2-second restore, I find the 1-2 minute total turnaround time to be fast enough for my purposes.

# Use
Follow the setup instructions on [WyoMurph's voipBL-CentOS6](https://github.com/WyoMurf/voipBL-CentOS6) repository, substituting this voipbl.sh script for his (Step 3 in his instructions).

# Improvements can be made
I haven't done much Linux/Unix scripting in many years, so I'm certain that this can be improved upon. But most importantly it works and has been stable for me for several weeks of operation.

I hope someone out there finds this useful.
