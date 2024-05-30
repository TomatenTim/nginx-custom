
ARG NGINX_VERSION=1.25.5
ARG RTMP_MODULE_VERSION=master
# TODO: set version of NJS

FROM nginx:${NGINX_VERSION} as build

# Install build dependencies
RUN apt-get update 
RUN apt-get install -y \
    openssh-client \
    git \
    wget \
    libxml2 \
    libxslt1-dev \
    libpcre3 \
    libpcre3-dev \
    zlib1g \
    zlib1g-dev \
    openssl \
    libssl-dev \
    libtool \
    automake \
    gcc \
    g++ \
    make


# Download nginx src
RUN wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" && \
tar -C /usr/src -xzvf nginx-${NGINX_VERSION}.tar.gz

WORKDIR /src

# Download Modules that need to be build
# Download nginx-rtmp-module
RUN git clone https://github.com/arut/nginx-rtmp-module.git
RUN git -C ./nginx-rtmp-module checkout ${RTMP_MODULE_VERSION}

# Build nginx modules
WORKDIR /usr/src/nginx-${NGINX_VERSION}
RUN NGINX_ARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p')
RUN ./configure \
    --with-pcre \
    --with-compat \
    --with-stream \
    --with-http_ssl_module \
    --with-http_auth_request_module \
    --add-dynamic-module=/src/nginx-rtmp-module \
    ${NGINX_ARGS}
RUN make modules





# Make minimal image with modules
FROM nginx:${NGINX_VERSION} as runner

# Download modules
RUN apt-get update
RUN apt-get install -y \
    nginx-module-njs

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# Copy modules
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_rtmp_module.so /usr/lib/nginx/modules/


RUN mkdir -p /config
COPY nginx.conf /config/nginx.conf

# create main config file
RUN mkdir -p /etc/nginx
RUN touch /etc/nginx/nginx.conf

# set user
RUN echo "user nginx;" | tee /etc/nginx/nginx.conf
# Imports the dynamic modules
RUN echo "load_module /usr/lib/nginx/modules/ngx_rtmp_module.so;" | tee -a /etc/nginx/nginx.conf
RUN echo "load_module /usr/lib/nginx/modules/ngx_http_js_module.so;" | tee -a /etc/nginx/nginx.conf

# logs
RUN echo "error_log /var/log/nginx/error.log warn;" | tee -a /etc/nginx/nginx.conf
# Imports the config file at /config/nginx.conf
RUN echo "include /config/nginx.conf;" | tee -a /etc/nginx/nginx.conf

VOLUME [ "/config" ]
VOLUME [ "/logs" ]
