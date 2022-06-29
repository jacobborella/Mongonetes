FROM ubuntu:latest
RUN apt-get update
RUN apt install -y default-jdk
COPY embedded-jetty-hello-world-1.jar embedded-jetty-hello-world-1.jar
CMD java -jar embedded-jetty-hello-world-1.jar