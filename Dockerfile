FROM redhat/ubi8

ARG USERNAME=dotmatics
ARG TOMCAT_VERSION=8.5.77
ARG OPENBABEL_VERSION=openbabel-2.4.1
ARG CORRETTO_VERSION=1.8.0_322.b06-2
ARG DOTMATICS_VERSION=2021.1-8666-s

RUN set -eux \
    && export GNUPGHOME="$(mktemp -d)" \
    && curl -fL -o corretto.key https://yum.corretto.aws/corretto.key \
    && gpg --batch --import corretto.key \
    && gpg --batch --export --armor '6DC3636DAE534049C8B94623A122542AB04F24E3' > corretto.key  \
    && rpm --import corretto.key \
    && rm -r "$GNUPGHOME" corretto.key \
    && curl -fL -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo \
    && grep -q '^gpgcheck=1' /etc/yum.repos.d/corretto.repo \
    && echo "priority=9" >> /etc/yum.repos.d/corretto.repo \
    && yum install -y java-1.8.0-amazon-corretto-devel-$CORRETTO_VERSION \
    && (find /usr/lib/jvm/java-1.8.0-amazon-corretto -name src.zip -delete || true) \
    && yum install -y fontconfig \
                      shadow-utils \
                      sudo \
                      which \
                      tar \
                      cairo \
                      swig \
                      python38-devel \
                      cmake \
                      gcc-c++ \
                      make \
                      initscripts \
                      unzip \
    && yum clean all

ENV LANG C.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-amazon-corretto
ENV CATALINA_HOME=/opt/tomcat/apache-tomcat-$TOMCAT_VERSION

# add sudo user
RUN useradd -ms /bin/bash $USERNAME \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/${USERNAME}

# download tomcat
RUN cd /tmp \
  && curl -O https://dlcdn.apache.org/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz

# extract and move to directory
RUN mkdir -p /opt/tomcat 

RUN tar -xf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz

RUN mv apache-tomcat-${TOMCAT_VERSION} /opt/tomcat/ \
  && chown -R $USERNAME: /opt/tomcat \
  && chmod +x /opt/tomcat/apache-tomcat-${TOMCAT_VERSION}/bin/*.sh \
  && echo "set JAVA_OPTS=%JAVA_OPTS% -Dfile.encoding=UTF-8" >> /opt/tomcat/apache-tomcat-${TOMCAT_VERSION}/bin/catalina.bat \
  && sed -i '124 a JAVA_OPTS=\"\$JAVA_OPTS -Xmx2048m -XX:+UseG1GC\"\nexport JAVA_OPTS' /opt/tomcat/apache-tomcat-${TOMCAT_VERSION}/bin/catalina.sh \
  && rm /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz

# # install openbabel
# COPY ${OPENBABEL_VERSION}.tar.gz /tmp/

# RUN tar -xzf /tmp/${OPENBABEL_VERSION}.tar.gz \
#   && mv ${OPENBABEL_VERSION} /usr/local/bin/obabel \
#   && rm /tmp/${OPENBABEL_VERSION}.tar.gz

# RUN mkdir /usr/local/bin/obabel/build
# WORKDIR /usr/local/bin/obabel/build

# RUN cmake \
#   -D PYTHON_BINDINGS=ON \
#   -D RUN_SWIG=ON \
#   -D PYTHON_EXECUTABLE=/usr/bin/python3 \
#   -D PYTHON_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
#   -D DPYTHON_LIBRARY=$(python3 -c "import distutils.sysconfig as sysconfig; print(sysconfig.get_config_var('LIBDIR'))") \
#   -D CMAKE_INSTALL_PREFIX=/usr \
#   -D CMAKE_BUILD_TYPE=RELEASE \
#   ..

# RUN make -j $(nproc) \
#   && make install

COPY browser-install-${DOTMATICS_VERSION}.zip /tmp/
RUN unzip /tmp/browser-install-${DOTMATICS_VERSION}.zip -d /opt/tomcat/apache-tomcat-${TOMCAT_VERSION}/webapps/browser \
  && rm /tmp/browser-install-${DOTMATICS_VERSION}.zip \
  && chown -R $USERNAME: /opt/tomcat \
  && sed -ir 's/app.locale=GB/app.locale=US/g' /opt/tomcat/apache-tomcat-${TOMCAT_VERSION}/webapps/browser/WEB-INF/browser.properties \
  && sed -ir 's/db.sid=XE/db.sid=cwdb01/g' /opt/tomcat/apache-tomcat-${TOMCAT_VERSION}/webapps/browser/WEB-INF/browser.properties \
  && sed -ir 's/db.server=.+/db.server=10.0.2.72/g' /opt/tomcat/apache-tomcat-${TOMCAT_VERSION}/webapps/browser/WEB-INF/browser.properties \
  && sed -ir 's/db2.password=.+/db2.password=ds3_userdata/g' /opt/tomcat/apache-tomcat-${TOMCAT_VERSION}/webapps/browser/WEB-INF/browser.properties \
  && sed -ir 's/db5.password=.+/db5.password=pinpoint/g' /opt/tomcat/apache-tomcat-${TOMCAT_VERSION}/webapps/browser/WEB-INF/browser.properties \
  && sed -ir 's/db.dba.password=.+/db.dba.password=manager/g' /opt/tomcat/apache-tomcat-${TOMCAT_VERSION}/webapps/browser/WEB-INF/browser.properties \
  && sed -ir 's/db.dba.user=.+/db.dba.user=system/g' /opt/tomcat/apache-tomcat-${TOMCAT_VERSION}/webapps/browser/WEB-INF/browser.properties \
  && sed -ir 's/updates.settings=new/updates.settings=auto/g' /opt/tomcat/apache-tomcat-${TOMCAT_VERSION}/webapps/browser/WEB-INF/browser.properties
 

USER $USERNAME 
WORKDIR /home/$USERNAME
