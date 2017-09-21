FROM eclipse/stack-base:ubuntu
EXPOSE 4403 8000 8080 9876 22

LABEL che:server:8080:ref=tomcat8 che:server:8080:protocol=http che:server:8000:ref=tomcat8-debug che:server:8000:protocol=http che:server:9876:ref=codeserver che:server:9876:protocol=http

ENV MAVEN_VERSION=3.3.9 \
    ANT_VERSION=1.10.1 \
    JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64 \
    TOMCAT_HOME=/home/user/tomcat8 \
    TERM=xterm
ENV M2_HOME=/home/user/apache-maven-$MAVEN_VERSION
ENV ANT_HOME=/home/user/ant-$ANT_VERSION
ENV PATH=$JAVA_HOME/bin:$M2_HOME/bin:$ANT_HOME/bin:$PATH

RUN mkdir /home/user/tomcat8 /home/user/apache-maven-$MAVEN_VERSION $ANT_HOME && \
    wget -qO- "https://www.apache.org/dist/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz" | tar -zx --strip-components=1 -C $ANT_HOME && \
    wget -qO- "http://apache.ip-connect.vn.ua/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" | tar -zx --strip-components=1 -C /home/user/apache-maven-$MAVEN_VERSION/ && \
    wget -qO- "http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.24/bin/apache-tomcat-8.0.24.tar.gz" | tar -zx --strip-components=1 -C /home/user/tomcat8 && \
    rm -rf /home/user/tomcat8/webapps/* && \
    echo "export MAVEN_OPTS=\$JAVA_OPTS" >> /home/user/.bashrc
    
USER root
RUN set -ex; \
    key='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8'; \
    export GNUPGHOME="$(mktemp -d)"; \
    sudo gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    sudo gpg --export "$key" > /etc/apt/trusted.gpg.d/postgres.gpg; \
    rm -r "$GNUPGHOME"; \
    sudo apt-key list
ENV PG_MAJOR 9.5
ENV PG_VERSION 9.5.2-1

RUN sudo echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list

USER user

RUN sudo apt-get update \
    && sudo apt-get install -y postgresql-common \
    && sudo sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
    && sudo apt-get install -y \
        postgresql-$PG_MAJOR=$PG_VERSION \
        postgresql-contrib-$PG_MAJOR=$PG_VERSION \
    && sudo rm -rf /var/lib/apt/lists/*
RUN sudo mv -v /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample /usr/share/postgresql/ \
    && sudo ln -sv ../postgresql.conf.sample /usr/share/postgresql/$PG_MAJOR/ \
    && sudo sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample
RUN sudo mkdir -p /var/run/postgresql && sudo chown -R postgres:postgres /var/run/postgresql && sudo chmod g+s /var/run/postgresql

ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV PGDATA /var/lib/postgresql/data
RUN sudo mkdir -p "$PGDATA" && sudo chown -R postgres:postgres "$PGDATA" && sudo chmod 777 "$PGDATA"
VOLUME /var/lib/postgresql/data

CMD sudo pg_createcluster $PG_MAJOR main --start && sudo service postgresql start & tail -f /dev/null

