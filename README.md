logstash-ping
=============

Ping plugin for Logstash. Input example:
```
input {
  ping {
    host => ["yourhost.org", "example.com"]
    interval => 20 # interval between the ping sequence
    timeout => 10 # in seconds
  }
}
```
Alternatives:
 * parse the output of the /sbin/ping or ping.exe
 * use the collectd ping plugin

