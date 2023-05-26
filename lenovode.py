#!/usr/bin/python2

import sys
import getopt
import signal
import atexit
import logging

sys.path.insert(1, "lib")
from LenovoDE import LenovoDE



def signalHandler(sig, frame):
    if sig != signal.SIGINT:
        logging.critical("timeout contacting device")
    sys.exit(3)


def usage():
    print("""
lenovode.py -H -u -p [-t] [-h] [-v[v]]
  -H, --host     : IP/DNS address
  -u, --username : username to login
  -p, --password : password
  -t, --timeout  : timeout in seconds
  -h, --help     : show help/usage
  -v, --verbose  : verbose
""")


def main(argv):
    host = username = password = None
    timeout = 10

    try:
        opts, args = getopt.getopt(argv,
                                   "hqvH:u:p:t:n:w:c:",
                                   ["host=",
                                    "help",
                                    "verbose",
                                    "username=",
                                    "password=",
                                    "timeout="])
    except getopt.GetoptError:
        sys.exit(3)

    verbosity = 1
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit()
        elif opt in ("-H", "--host"):
            host = arg
        elif opt in ("-u", "--username"):
            username = arg
        elif opt in ("-p", "--password"):
            password = arg
        elif opt in ("-t", "--timeout"):
            timeout = int(arg)
        elif opt in ("-q"):
            verbosity = 0
        elif opt in ("-v"):
            if (verbosity > 0 and verbosity < 5):
                verbosity += 1

    logging.basicConfig(format="%(asctime)s %(levelname)s: %(message)s",
                        datefmt="%d.%m.%Y %I:%M:%S",
                        level=[100,
                                logging.CRITICAL,
                                logging.ERROR,
                                logging.WARNING,
                                logging.INFO,
                                logging.DEBUG][verbosity])

    for i in [host, username, password]:
        if i is None:
            logging.error("missing required parameter")
            usage()
            sys.exit(3)

    signal.alarm(timeout)

    os = LenovoDE(host, 443, username, password, timeout)
    if not os.login():
        logging.error("unable to login")
        sys.exit(3)

    atexit.register(os.logout)

    logging.info("connection to {0} opened".format(host))

    size = used = 0
    fs = os.storagepools("*")
    for i in fs:
        size += i[1]
        used += i[2]

    print("aggr;{0:.0f};{1:.0f}".format(used, size))

    size = used = compress = dedup = 0
    fs = os.filesystems("*")
    for i in fs:
        size += i[1]
        used += i[2]
        compress += i[7]
        dedup += i[8]

    for i in fs:
        print("volumes;{5};{0};{1:.0f};{2:.0f};{3:.0f};{4:.0f}".format(i[0], i[7], i[8], i[2], i[1], i[9]))

    fs = os.luns("*")
    for i in fs:
        size += i[1]
        used += i[2]
        compress += i[7]
        dedup += i[8]

    for i in fs:
        print("volumes;{5};{0};{1:.0f};{2:.0f};{3:.0f};{4:.0f}".format(i[0], i[7], i[8], i[2], i[1], i[9]))

    print("vol;{0:.0f};{1:.0f};{2:.0f};{3:.0f}".format(compress, dedup, used, size))

    logging.info("connection to {0} closed".format(host))
    sys.exit(0)


if __name__ == "__main__":
    signal.signal(signal.SIGINT, signalHandler)
    signal.signal(signal.SIGALRM, signalHandler)
    main(sys.argv[1:])
