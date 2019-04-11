#! /usr/bin/env python

from sys import argv
import random
import hazelcast

if len(argv) != 3:
    print(" Usage: %s <ConnectionString e.g. hzhost1:port,hzhost2:port,...> <NumOfKeys e.g. 100000>" %argv[0])
    exit(1)

connstr = argv[1]
numkeys = int(argv[2])

config = hazelcast.ClientConfig()
for hp in connstr.split(','):
  config.network_config.addresses.append(hp)
client = hazelcast.HazelcastClient(config)

m = client.get_map("smoketest")
for k in xrange(1, numkeys+1):
  m.put("%s" %k, random.randint(1,numkeys))
client.shutdown()
