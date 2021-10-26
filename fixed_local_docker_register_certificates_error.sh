BUILDER=$(sudo docker ps | grep buildkitd | cut -f1 -d' ')
sudo docker cp YOUR-CA.crt $BUILDER:/usr/local/share/ca-certificates/
sudo docker exec $BUILDER update-ca-certificates
sudo docker restart $BUILDER
