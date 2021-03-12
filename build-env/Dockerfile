# https://hub.docker.com/_/ubuntu/
FROM ubuntu:18.04

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install --yes \
      automake \
      bash \
      bison \
      curl \
      g++ \
      gawk \
      git \
      gpg \
      jq \
      libffi-dev \
      libgdbm-dev \
      libgmp-dev \
      libncurses5-dev \
      libreadline-dev \
      libsqlite3-dev \
      libssl-dev \
      libtool \
      libyaml-dev \
      locales \
      make \
      nano \
      openjdk-8-jdk \
      p7zip-full \
      pkg-config \
      rsync \
      shellcheck \
      sqlite3 \
      ssh \
      sudo \
      tzdata \
      unzip \
      zip \
      zlib1g-dev \
      && rm -rf /var/lib/apt/lists/*

# From https://serverfault.com/a/689947
# Configure timezone and locale
RUN /bin/bash -c 'echo "UTC" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    sed -i -e "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen && \
    echo "LANG='en_US.UTF-8'">/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8'
ENV LANG=en_US.UTF-8

# install maven
ARG maven_version=3.6.3
RUN /bin/bash -c 'set -o pipefail && \
    cd opt && \
    curl https://mirror.checkdomain.de/apache/maven/maven-3/${maven_version}/binaries/apache-maven-${maven_version}-bin.tar.gz | tar xz && \
    ln -sf /opt/apache-maven-${maven_version}/bin/mvn /usr/local/bin/mvn && \
    cd ..'

# install ruby
ARG ruby_version=2.7
RUN /bin/bash -c 'set -o pipefail && \
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
    curl -sSL https://get.rvm.io | bash -s stable && \
    source /etc/profile.d/rvm.sh && \
    rvm install ${ruby_version} && \
    rvm use ${ruby_version} --default && \
    ruby -v'

RUN groupadd pmd-ci && useradd --gid pmd-ci --groups sudo,rvm \
             --shell /bin/bash --create-home --password "" \
             pmd-ci
USER pmd-ci:pmd-ci
WORKDIR /home/pmd-ci
RUN sudo mkdir -p /workspaces/pmd/pmd && \
    sudo chown -R pmd-ci:pmd-ci /workspaces && \
    ln -sf /workspaces /home/pmd-ci/workspaces
COPY create-gh-actions-env.sh /home/pmd-ci

# setup ruby for current user "pmd-ci"
RUN /bin/bash --login -c 'rvm user gemsets && \
    rvm use ${ruby_version} && \
    echo "rvm use ${ruby_version}" >> $HOME/.profile && \
    rmdir 1'

CMD ["/bin/bash", "--login"]

#
# build with: docker build -t pmd-build-env .
# run with: docker run -it pmd-build-env
#