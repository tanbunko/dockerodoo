FROM ubuntu:20.04 AS os
LABEL vendor="telesoho" tag="telesoho/dockerodoo" version="1.0"

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM" > /log


# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        # TO REEMOVE WHEN PACKAGED
        gsfonts \
        libssl-dev \
        node-less \
        python3-num2words \
        python3-pdfminer \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        # TO REMOVE WHEN PACKAGED
        python3-openssl \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        xz-utils \
        dumb-init \
        lsb-release

# Install postgresql-client
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN apt update && apt install -yq postgresql-client


RUN dpkgArch="$(dpkg --print-architecture)"; \
    release="$(lsb_release -cs)"; \
    curl -o wkhtmltox.deb -sSL "https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.${release}_${dpkgArch}.deb" \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf wkhtmltox.deb


# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

FROM os as odoo15

# Switch to user odoo to create the folders mapped with volumes, else the
# corresponding folders will be created by root on the host

# Create the odoo user
RUN useradd --create-home --home-dir /opt/odoo --no-log-init odoo

USER odoo

RUN /bin/bash -c "mkdir -p /opt/odoo/{etc,src/odoo,custom,data,ssh}"


# Install odoo src
ARG ODOO_COMMIT_ID=82562cc25c10500d30056ca19d816c1d211a24eb
ARG ODOO_SHA=12631633fbebdceb06899f4e2d1e035917310376
# RUN curl -H "Authorization: token $github_token" 


WORKDIR /opt/odoo/src
RUN curl -o odoo.tgz -L https://github.com/odoo/odoo/tarball/${ODOO_COMMIT_ID}

FROM odoo15 as check_odoo15 

RUN if [[ "$ODOO_SHA" != "" ]] ; then  echo "${ODOO_SHA} odoo.tgz" | sha1sum -c -; else echo "Warnning: No SHA sum check!"  ; fi \
    && tar --transform='s|^odoo-odoo-[^\/]*|odoo|' -xzf odoo.tgz \
    && rm odoo.tgz

FROM check_odoo15 as install_odoo_requirements 


USER 0

# RUN  apt-get install -y libpq-dev \
#       python3-dev  \
#       python3-wheel \
#       libldap2-dev \
#       libsasl2-dev \
#       python3-setuptools \
#       libjpeg-dev \
#       libxml2-dev \
#       libxslt1-dev

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl \
      python3 \
      build-essential \
      python3-dev  \
      python3-wheel \
      libxslt-dev \
      libzip-dev \
      libldap2-dev \
      libsasl2-dev \
       npm \
      python3-setuptools \
      node-less \
      libjpeg-dev \
      libpq-dev \
      libxml2-dev \
      libxslt1-dev \
      libffi-dev  \
      ca-certificates \
      dirmngr \
      fonts-noto-cjk \
      gnupg \
      libssl-dev \
      node-less \
      python3-num2words \
      python3-pdfminer \
      python3-pip \
      python3-phonenumbers \
      python3-pyldap \
      python3-qrcode \
      python3-renderpm \
      python3-slugify \
      python3-vobject \
      python3-watchdog \
      python3-xlrd \
      python3-xlwt \
      xz-utils \
      sudo
            
# rm -rf /var/lib/apt/lists/*
RUN pip3 install --upgrade pip
# Install Odoo python dependencies
RUN pip3 install -r /opt/odoo/src/odoo/requirements.txt


FROM install_odoo_requirements AS stage_setting


# Startup script for custom setup
# ADD startup.sh /opt/scripts/startup.sh

VOLUME [ \
  "/opt/odoo/etc", \
  "/opt/odoo/custom", \
  "/opt/odoo/data", \
  "/opt/odoo/ssh", \
  "/opt/scripts" \
]

# Expose Odoo services
EXPOSE 8069 8071 8072

ADD boot /usr/bin/boot
ADD save_environ /usr/bin/save_environ
ENTRYPOINT [ "/usr/bin/dumb-init", "/usr/bin/boot" ]
CMD [ "help" ]
