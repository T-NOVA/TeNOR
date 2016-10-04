FROM ruby:2.2.5

MAINTAINER Josep Batallé "josep.batalle@i2cat.net"
#docker build -t tnova/tenor .
#docker run -itd -p 4000:4000 -p 8000:8000 -p 9000:9000 -v /opt/mongo:/var/lib/mongodb -v /opt/gatekeeper:/root/gatekeeper tnova/tenor bash
#docker run -it tnova/tenor bash
#docker exec -i -t f9ff694e0872 /bin/bash

ENV TENOR_PORT 4000
ENV TENOR_UI_PORT 9000
ENV GK_PORT 8000
ENV MONGODB_PORT 27017

RUN apt-get update

# Installation:
ENV GPG_KEYS \
	DFFA3DCF326E302C4787673A01C4E7FAAAB2461C \
	42F3E95A2C4F08279C4960ADD68FA50FEA312927 \
	492EAFE8CD016A07919F1D2B9ECBEC467F0CEB10
RUN set -ex \
	&& for key in $GPG_KEYS; do \
	apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done
RUN echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.2 main" > /etc/apt/sources.list.d/mongodb-org.list
RUN apt-get update
RUN apt-get -q -y install \
    git nano \
    mongodb-org sqlite3 libsqlite3-dev \
    byobu \
    gcc sudo uuid-runtime

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

WORKDIR /root
RUN apt-get -q -y install curl
RUN mkdir -p /usr/local/go && curl https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz | tar xvzf - -C /usr/local/go --strip-components=1

RUN mkdir /opt/go
ENV GOPATH=/opt/go
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
RUN mkdir -p /opt/go/src/github.com/piyush82
RUN cd /opt/go/src/github.com/piyush82 && git clone https://github.com/piyush82/auth-utils.git
RUN cd /opt/go/src/github.com/piyush82/auth-utils && go get && go install

# Clone the conf files into the docker container
RUN git clone https://github.com/jbatalle/TeNOR /root/TeNOR

RUN mkdir /root/gatekeeper
RUN cp /opt/go/src/github.com/piyush82/auth-utils/gatekeeper.cfg /root/gatekeeper/gatekeeper.cfg
RUN cp /opt/go/src/github.com/piyush82/auth-utils/gatekeeper.cfg /root/TeNOR/gatekeeper.cfg

ENV RAILS_ENV development
WORKDIR /root/TeNOR
RUN bundle --version
RUN cat Gemfile
RUN gem install bundle
RUN bundle install
RUN ./tenor_install.sh 1

RUN chown -R mongodb:mongodb /var/lib/mongodb

EXPOSE $TENOR_PORT
EXPOSE $TENOR_UI_PORT
EXPOSE $GK_PORT
EXPOSE $MONGODB_PORT

#update rake start to bundle exec rake start
RUN sed -i 's/rake start/bundle exec rake start/g' /root/TeNOR/invoker.ini

RUN echo -e '#!/bin/bash \n/opt/go/bin/auth-utils &' > gatekeeperd
RUN mv gatekeeperd /etc/init.d/gatekeeperd
RUN chmod +x /etc/init.d/gatekeeperd
RUN chown root:root /etc/init.d/gatekeeperd

ENTRYPOINT /etc/init.d/gatekeeperd start && /etc/init.d/mongod start && invoker start invoker.ini && /bin/bash
