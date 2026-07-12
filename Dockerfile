FROM ubuntu:26.04

ARG mavenversion=3.9.16
ARG gradleversion=9.6.1
ARG nvmversion=v0.40.5

RUN cat > /etc/apt/sources.list.d/ubuntu.sources <<EOL
Types: deb
URIs: http://hk.archive.ubuntu.com/ubuntu/
Suites: resolute resolute-updates resolute-backports resolute-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOL
RUN apt-get update && apt-get install -y \
    vim \
	curl \
	git \
	zip \
	# openjdk-17-jdk \
	openjdk-21-jdk \
	openjdk-25-jdk \
	tzdata \
	sudo \
	xdg-utils x11-apps fonts-wqy-microhei fonts-wqy-zenhei \
	&& rm -rf /var/lib/apt/lists/*
RUN ln -fs /usr/share/zoneinfo/Asia/Macau /etc/localtime && dpkg-reconfigure -f noninteractive tzdata
RUN update-alternatives --set java /usr/lib/jvm/java-21-openjdk-amd64/bin/java \
	&& update-alternatives --set javac /usr/lib/jvm/java-21-openjdk-amd64/bin/javac \
	&& update-alternatives --set jar /usr/lib/jvm/java-21-openjdk-amd64/bin/jar
#/usr/lib/jvm/java-17-openjdk-amd64/bin/java

WORKDIR /opt
RUN curl "https://dlcdn.apache.org/maven/maven-3/$mavenversion/binaries/apache-maven-$mavenversion-bin.tar.gz" -o maven.tgz \
	&& tar zxvf maven.tgz && rm maven.tgz \
	&& curl -L "https://services.gradle.org/distributions/gradle-$gradleversion-bin.zip" -o gradle.zip \
	&& unzip gradle.zip && rm gradle.zip

RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/ubuntu
USER ubuntu
WORKDIR /home/ubuntu
ENV PATH="/opt/apache-maven-$mavenversion/bin:/opt/gradle-$gradleversion/bin:${PATH}"

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$nvmversion/install.sh | bash
RUN bash -lc "source /home/ubuntu/.nvm/nvm.sh && nvm install 26"
#RUN bash -lc "source /home/ubuntu/.nvm/nvm.sh && nvm -v && node -v && npm -v"

RUN mkdir /home/ubuntu/.m2 && mkdir /home/ubuntu/sourcecode
