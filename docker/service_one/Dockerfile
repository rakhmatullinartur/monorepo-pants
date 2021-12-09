FROM python:3.9
ENTRYPOINT ["/bin/service_one"]
RUN apt-get install
#COPY src/docker/hw/msg.txt /var/msg
COPY services.service_one/main.pex /bin/service_one
