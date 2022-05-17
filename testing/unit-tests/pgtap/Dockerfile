# Copied from:
# https://github.com/walm/docker-pgtap/blob/master/Dockerfile
#
# But with PGTAP updated to version v1.1.0

FROM postgres:13.2

RUN apt-get update \
    && apt-get install -y build-essential git-core libv8-dev curl postgresql-server-dev-$PG_MAJOR \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# install pg_prove
RUN curl -LO http://xrl.us/cpanm \
    && chmod +x cpanm \
    && ./cpanm TAP::Parser::SourceHandler::pgTAP

# install pgtap
ENV PGTAP_VERSION v1.2.0
RUN git clone https://github.com/theory/pgtap.git \
    && cd pgtap && git checkout tags/$PGTAP_VERSION \
    && make \
    && make install

# add testing script
ADD ./test.sh /test.sh
RUN chmod +x /test.sh

# sets entry point
WORKDIR /
CMD ["/test.sh"]
ENTRYPOINT ["/test.sh"]
