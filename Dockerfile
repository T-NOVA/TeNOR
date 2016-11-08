FROM ruby:2.2.5

MAINTAINER Josep Batallé "josep.batalle@i2cat.net"
#docker build -t tnova/tenor .
#docker run -itd -p 4000:4000 -p 9000:9000 -v /opt/mongo:/var/lib/mongod tnova/tenor bash
#docker run -it tnova/tenor bash
#docker exec -i -t f9ff694e0872 /bin/bash

ENV TENOR_PORT 4000
ENV TENOR_UI_PORT 9000
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
    sudo uuid-runtime

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

WORKDIR /root
RUN apt-get -q -y install curl

# Clone the conf files into the docker container
RUN git clone https://github.com/T-NOVA/TeNOR /root/TeNOR

ENV RAILS_ENV development
WORKDIR /root/TeNOR
RUN bundle --version
RUN cat Gemfile
RUN gem install bundle
RUN bundle install
RUN sed -i 's/rake db:seed/bundle exec rake db:seed/g' tenor_install.sh
RUN ./tenor_install.sh 1

RUN chown -R mongodb:mongodb /var/lib/mongodb

EXPOSE $TENOR_PORT
EXPOSE $TENOR_UI_PORT
EXPOSE $MONGODB_PORT

#update rake start to bundle exec rake start
RUN sed -i 's/rake start/bundle exec rake start/g' /root/TeNOR/invoker.ini

ENTRYPOINT /etc/init.d/mongod start && invoker start invoker.ini && /bin/bash
