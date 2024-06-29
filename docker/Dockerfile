FROM ubuntu:20.04

# setup environment
ARG USER_DOCKER=corundum
ENV USER_DOCKER=${USER_DOCKER}
ENV HOME_DOCKER=/home/${USER_DOCKER}

# install sudo
RUN apt update

RUN apt install -y iverilog
RUN apt install -y gtkwave
RUN apt install -y python3-pip
RUN pip install cocotb		\
    		cocotb-bus	\
		cocotb-test	\
		cocotbext-axi	\
		cocotbext-eth	\
		cocotbext-pcie	\
		pytest	       	\
		scapy		\
		pytest-xdist	\
		tox		\
		pytest-sugar

# setup sudo user
RUN adduser --disabled-password --gecos '' $USER_DOCKER
RUN adduser $USER_DOCKER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir -p ${HOME_DOCKER}/corundum

# setup container environment
USER $USER_DOCKER
WORKDIR $HOME_DOCKER
CMD ["/bin/bash"]
