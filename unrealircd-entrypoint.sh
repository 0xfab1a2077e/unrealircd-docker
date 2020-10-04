#!/bin/sh

chown -R ircd:ircd /home/ircd/unrealircd

exec "$@"
