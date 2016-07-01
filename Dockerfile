FROM ruby:2.2

MAINTAINER Josep Batallé "josep.batalle@i2cat.net"
#docker run -itd -p 4000:4000 -p 8000:8000 tnova/tenor
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

RUN cp /root/go/src/github.com/piyush82/auth-utils/gatekeeper.cfg /root/gatekeeper.cfg

# Clone the conf files into the docker container
RUN git clone https://github.com/T-NOVA/TeNOR /root/TeNOR

WORKDIR /root/TeNOR
RUN cd /root/TeNOR && gem install bundle && bundle install && ./tenor_install.sh
RUN cd /root/TeNOR/ui && npm install -g grunt grunt-cli bower && npm install && bower install --allow-root && gem install compass
#ADD development.sh /root/TeNOR/development.shgo/bin/auth-utils
#RUN cd /root/TeNOR && ./development.sh
#RUN cd /root/TeNOR && ./loadModules.sh

EXPOSE $TENOR_PORT
EXPOSE $TENOR_UI_PORT
EXPOSE $GK_PORT
EXPOSE $MONGODB_PORT

RUN /etc/init.d/mongod start
RUN cd /root && go/bin/auth-utils &

#ENTRYPOINT ["sh", "development.sh"]
ENV RAILS_ENV development
