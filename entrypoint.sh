#!/bin/sh -e

if [ -n "$UMASK" ]
then
    echo "UMASK env variable set, setting file mode creation mask to $UMASK"
    umask "$UMASK"
else
    echo "UMASK env variable not set, keeping default access permission mask"
fi

# Try to make qbt config dir in case it doesn't exist
mkdir -p /config/qBittorrent

# Try to apply default config in case it doesn't exist
if [ ! -f /config/qBittorrent/qBittorrent.conf ]
then
	cp /default/qBittorrent.conf /config/qBittorrent/qBittorrent.conf
fi

# Run qBittorrent
exec "qbittorrent-nox"
