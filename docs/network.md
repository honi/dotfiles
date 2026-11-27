# Network issues

## A domain doesn't resolve because of the network's DNS filter

### Symptom

A domain that works on other networks fails here, usually with certificate errors or a block page.

### Cause

The network's DNS (common on university, office and guest Wi-Fi) answers for blocked domains with the address of its own block page.

### Check

Compare the network's answer with a public resolver's. If they differ, the network is filtering.

```bash
resolvectl query <domain>
dig @1.1.1.1 <domain>
```

### Fix

Use a public resolver on that Wi-Fi connection only; other networks keep their own DNS.

```bash
nmcli connection modify "<connection>" ipv4.dns "1.1.1.1 9.9.9.9" ipv4.ignore-auto-dns yes
nmcli connection up "<connection>"
```

Find the connection name:

```bash
nmcli -t -f NAME,TYPE,DEVICE connection show --active
```

Undo:

```bash
nmcli connection modify "<connection>" ipv4.dns "" ipv4.ignore-auto-dns no
nmcli connection up "<connection>"
```

If the public resolver doesn't answer either, the network blocks outbound DNS: use another network or ask its operator for an allowlist.
