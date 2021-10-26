## 安装私有docker registry

0. 参考

    ```
    https://docs.docker.com/registry/
    https://docs.docker.com/registry/spec/api/
    https://docs.docker.com/registry/configuration/
    ```

1. 配置/etc/ssl/openssl.cnf

    为了避免使用ip登录时导致下列错误:

    ```log
    Error response from daemon: Get https://192.168.2.22:5000/v2/: x509: cannot validate certificate for 192.168.2.22 because it doesn't contain any IP SANs
    http: TLS handshake error from 192.168.2.22:38696: remote error: tls: bad certificate
    ```

    需要把IP地址加到v3_ca区域

    ```sh
    $ sudo vi /etc/ssl/openssl.cnf
    ```

    ```conf
    [ v3_ca ]
    subjectAltName = IP:192.168.10.100
    ```

1. 生成自签名认证

    建立文件目录

    ```sh
    $ mkdir -p ~/my.docker.hub/{data,registry/certs}
    $ cd ~/my.docker.hub/registry/certs
    ```

    并生成自签名认证：

    ```sh
    $ openssl req -x509 -nodes -sha256 -newkey rsa:4096 \
    -keyout registry.key -out registry.crt \
    -days 365 -subj '/CN=192.168.10.100'
    ```

    将认证文件拷贝到```/etc/docker/certs.d/```

    ```sh
    $ sudo mkdir -p "/etc/docker/certs.d/192.168.10.100:5000"
    $ sudo cp registry.crt "/etc/docker/certs.d/192.168.10.100:5000"
    ```

    重启docker

    ```sh
    $ sudo systemctl restart docker
    ```

1. 创建htpasswd
    
    ```sh
    $ sudo apt install apache2-utils
    $ cd ~/my.docker.hub/registry
    $ htpasswd -Bbn admin admin > htpasswd
    ```

1. 配置config.yml

    详细参考： https://docs.docker.com/registry/configuration/

    创建config.yml文件：

    ```sh
    $ vi ~/my.docker.hub/registry/config.yml 
    ```

    ```yml
    version: 0.1
    log:
      accesslog:
        disabled: false
      level: info
      fields:
        service: registry
        environment: development
    storage:
      filesystem:
        rootdirectory: /var/lib/registry
      delete:
        enabled: true
      cache:
        blobdescriptor: inmemory
    auth:
      htpasswd:
        realm: class-realm
        path: /etc/docker/registry/htpasswd
    http:
      addr: 0.0.0.0:5000
      host: https://192.168.10.100:5000
      secret: asecretforlocaldevelopment
      tls:
        certificate: /etc/docker/registry/certs/registry.crt
        key: /etc/docker/registry/certs/registry.key
      debug:
        addr: 0.0.0.0:5001
    ```

1. 配置docker-compose.yml

    ```sh
    $ vi ~/my.docker.hub/docker-compose.yml
    ```

    ```yml
    version: '3.3'

    services:
        registry:
            container: registry
            restart: always
            image: registry:2
            ports:
                - "5000:5000"
            volumes:
                - ./data:/var/lib/registry
                - ./registry:/etc/docker/registry
    ```

1. 启动docker registry

    ```sh
    $ cd ~/my.docker.hub
    $ docker-compose up -d
    ```

