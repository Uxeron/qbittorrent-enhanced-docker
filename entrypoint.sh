#!/bin/sh -e

# Try to make qbt config dir in case it doesn't exist
mkdir -p /config/qBittorrent

# Try to apply default config in case it doesn't exist
if [ ! -f /config/qBittorrent/qBittorrent.conf ]
then
	cp /default/qBittorrent.conf /config/qBittorrent/qBittorrent.conf
fi

# Run qBittorrent
exec "qbittorrent-nox"
