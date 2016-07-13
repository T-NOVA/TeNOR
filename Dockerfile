FROM ruby:2.2

MAINTAINER Josep Batallé "josep.batalle@i2cat.net"
#docker build -t tnova/tenor .
#docker run -itd -p 4000:4000 -p 8000:8000 -p 9000:9000 -v /opt/mongo:/var/lib/mongodb -v /opt/gatekeeper:/root/gatekeeper tnova/tenor_test bash
#docker exec -i -t f9ff694e0872 /bin/bash
#after run the docker, execute the following scripts:
# ./development.sh
# ./loadModules.sh

ENV TENOR_PORT 4000
ENV TENOR_UI_PORT 9000
ENV GK_PORT 8000
ENV MONGODB_PORT 27017

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
    nodejs-legacy npm \
    git nano \
    mongodb-org \
    byobu \
    gcc sudo uuid-runtime

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

WORKDIR /root
#tar -C /usr/local -xzf go1.4.2.linux-amd64.tar.gz
RUN \
mkdir -p /usr/local/go && \
  curl https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz | tar xvzf - -C /usr/local/go --strip-components=1

COPY dependencies/install_gatekeeper.sh /root/install_gatekeeper.sh
RUN sh install_gatekeeper.sh

RUN mkdir /root/gatekeeper && cp /root/go/src/github.com/piyush82/auth-utils/gatekeeper.cfg /root/gatekeeper/gatekeeper.cfg

# Clone the conf files into the docker container
RUN git clone https://github.com/T-NOVA/TeNOR /root/TeNOR

WORKDIR /root/TeNOR
RUN cd /root/TeNOR && gem install bundle && bundle install && ./tenor_install.sh
RUN cd /root/TeNOR/ui && npm install -g grunt grunt-cli bower && npm install
RUN cd /root/TeNOR/ui && bower install --allow-root
RUN cd /root/TeNOR/ui && gem install compass
RUN ln -s /usr/local/bundle/bin/compass /usr/local/bin/compass

RUN chown -R mongodb:mongodb /var/lib/mongodb

EXPOSE $TENOR_PORT
EXPOSE $TENOR_UI_PORT
EXPOSE $GK_PORT
EXPOSE $MONGODB_PORT

ADD dependencies/development.sh /root/TeNOR/development.sh

#ENTRYPOINT ["sh", "development.sh"]
ENV RAILS_ENV development
ENTRYPOINT sh development.sh && /bin/bash
