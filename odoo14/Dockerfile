FROM ubuntu:20.04 AS stage_install_apt0

LABEL vendor="telesoho" tag="telesoho/odoo" version="1.0"


# -x enables a mode of the shell where all executed commands are printed to the terminal.
# -o pipefail this setting prevents errors in a pipeline from being masked. I
SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG=C.UTF-8

# Set timezone to UTC
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Install APT dependencies
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
      npm \
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

RUN npm install -g rtlcss

FROM stage_install_apt0 as stage_install_apt
# Install wkhtmltopdf based on QT5
RUN curl -o wkhtmltox.deb -L https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.focal_amd64.deb \
    && echo 'ae4e85641f004a2097621787bf4381e962fb91e1 wkhtmltox.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb


# Use dumb-init as init system to launch the boot script
RUN curl -o dumb-init.deb -L https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64.deb \
    && echo '50634ce2eb51a37ff5c1e3106790c9440ce7910d dumb-init.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./dumb-init.deb \
    && rm -rf /var/lib/apt/lists/* dumb-init.deb


# Install postgresql-client
RUN apt update && apt install -yq lsb-release
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN apt update && apt install -yq postgresql-client


FROM stage_install_apt AS install_odoo_src

# Switch to user odoo to create the folders mapped with volumes, else the
# corresponding folders will be created by root on the host


# Create the odoo user
RUN useradd --create-home --home-dir /opt/odoo --no-log-init odoo

USER odoo

RUN /bin/bash -c "mkdir -p /opt/odoo/{etc,src/odoo,custom,data,ssh}"


# Install odoo src
ARG ODOO_COMMIT_ID=ce1a0171f61d2808470c185a91e9f8299e4efd25
ARG ODOO_SHA=12631633fbebdceb06899f4e2d1e035917310376
# RUN curl -H "Authorization: token $github_token" 

WORKDIR /opt/odoo/src
RUN curl -o odoo.tgz -L https://github.com/odoo/odoo/tarball/${ODOO_COMMIT_ID} \
    && echo "${ODOO_SHA} odoo.tgz" | sha1sum -c - \
    && tar --transform='s|^odoo-odoo-[^\/]*|odoo|' -xzf odoo.tgz \
    && rm odoo.tgz


FROM install_odoo_src AS install_odoo_requirements

USER 0

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
