#!/bin/bash

export PATH=/home/ubuntu/.rbenv/shims:/home/ubuntu/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
cd /home/ubuntu/main/CircuitVerse

case $1 in
  start)
	 /home/ubuntu/.rbenv/shims/procodile start ;;
  stop)
	 /home/ubuntu/.rbenv/shims/procodile stop ;;
  *)
	echo "usage: xyz {start|stop}" ;;
esac
exit 0
