################################################################################
# Dockerfile to build Percona XtraDB Cluster 5.7
# Based on Centos 7
################################################################################

# Set the base image to Centos
FROM centos:centos7

# File Author / Maintainer
MAINTAINER Nicola Strappazzon nicola@swapbytes.com

# Add repository key
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

# Update the repository sources list
RUN yum -y update

############################# BEGIN INSTALLATION ###############################
# Install the Percona repository package
RUN yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm

# Install the Percona XtraDB Cluster packages
RUN yum -y install Percona-XtraDB-Cluster-57

# Copy custom config
COPY custom.cnf /etc/my.cnf.d/

# Copy galera config
COPY galera.cnf /etc/my.cnf.d/

# Copy script utility
COPY initialize.sh /root/initialize.sh
RUN chmod a+x /root/initialize.sh

############################## INSTALLATION END ################################

# Set the working directory
WORKDIR /var/lib/mysql

# Expose the default port
EXPOSE 3306 4567 4568

ENTRYPOINT ["/root/initialize.sh"]

CMD [""]
