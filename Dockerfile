FROM resin/rpi-raspbian:stretch

RUN set -ex \
    # Official Mopidy install for Debian/Ubuntu along with some extensions
    # (see https://docs.mopidy.com/en/latest/installation/debian/ )
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
        dumb-init \
        gcc \
        gnupg \
        gstreamer1.0-alsa \
        gstreamer1.0-plugins-bad \
        python-crypto \
        libc6-dev \
 && curl -L https://apt.mopidy.com/mopidy.gpg | apt-key add - \
 && curl -L https://apt.mopidy.com/mopidy.list -o /etc/apt/sources.list.d/mopidy.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        mopidy \
        mopidy-soundcloud \
        mopidy-spotify
RUN curl -L https://bootstrap.pypa.io/get-pip.py | python - \
 && apt-get install -y libxml2-dev libxslt1-dev python-dev libssl-dev git \
 && pip install -U six \
 && export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:/usr/include/python2.7/" \
 && pip install \
        Mopidy-Moped \
        Mopidy-YouTube \
        pyasn1 \
        pyopenssl \
        requests[security] \
        urllib \
        requests \
        youtube-dl \
 && git clone https://github.com/Prior99/mopidy-subidy.git \
 && cd mopidy-subidy && python setup.py install && cd .. \
 && mkdir -p /var/lib/mopidy/.config/mopidy \
 && ln -s /config/ /var/lib/mopidy/.config/mopidy \
    # Clean-up
 && apt-get purge --auto-remove -y \
        curl \
        gcc \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache

# Start helper script.
COPY entrypoint.sh /entrypoint.sh

# Default configuration.
COPY mopidy.conf /config/mopidy.conf

# Copy the pulse-client configuratrion.
COPY pulse-client.conf /etc/pulse/client.conf

# Allows any user to run mopidy, but runs by default as a randomly generated UID/GID.
ENV HOME=/var/lib/mopidy
RUN set -ex \
 && usermod -u 84044 mopidy \
 && groupmod -g 84044 audio \
 && chown mopidy:audio -R $HOME /entrypoint.sh \
 && chmod go+rwX -R $HOME /entrypoint.sh

# Runs as mopidy user by default.
USER mopidy

VOLUME ["/var/lib/mopidy/local", "/var/lib/mopidy/media"]

EXPOSE 6600 6680 5555/udp

ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint.sh"]
CMD ["/usr/bin/mopidy"]
