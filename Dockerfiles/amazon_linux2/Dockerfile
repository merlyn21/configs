FROM amazonlinux:2

RUN yum update -y
RUN amazon-linux-extras install -y php7.4
RUN yum install -y httpd mod_ssl

COPY ./start.sh /etc

EXPOSE 80 443
CMD ["/bin/bash", "/etc/start.sh"]
