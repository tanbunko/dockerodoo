# dockerodoo
odoo docker support init batch

FAQ:

## Custom registry, push error on self-signed cert

https://github.com/docker/buildx/issues/80#issuecomment-533844117

```sh
$ docker ps|grep 'moby/buildkit'
ee110c9e6dfc        moby/buildkit:buildx-stable-1   "buildkitd"              7 minutes ago       Up 7 minutes                                                                                       buildx_buildkit_mybuilder0

$ docker exec -it ee110c9e6dfc sh
$$ cat >> /etc/ssl/certs/ca-certificates.crt <<'EOF'
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
EOF
$$ exit

$ docker restart ee110c9e6dfc
```

OR https://github.com/docker/buildx/issues/80#issuecomment-541458458


```sh
BUILDER=$(sudo docker ps | grep buildkitd | cut -f1 -d' ')
sudo docker cp YOUR-CA.crt $BUILDER:/usr/local/share/ca-certificates/
sudo docker exec $BUILDER update-ca-certificates
sudo docker restart $BUILDER
```


if the `daemon.json` file does not exist, create it. Assuming there are no other settings in the file, it should have the following contents:

```
{
  "insecure-registries" : ["myregistry:5000"]
}
```

Substitute the address (`myregistry:5000`) with your insecure registry.

Restart docker daemon `sudo service docker restart`
