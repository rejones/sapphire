FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y ant openjdk-8-jdk-headless bison g++ patch make g++-multilib autoconf

ADD ./sapphire /opt/sapphire
ADD ./dot.ant.properties /opt/sapphire/jikesrvm/.ant.properties
ADD ./externals /opt/externals
ADD ./benchmark /opt/sapphire/benchmark
ADD ./benchmarks.txt /opt/sapphire/benchmarks.txt

RUN cd /opt/sapphire/jikesrvm/; ant cleanest; ant



