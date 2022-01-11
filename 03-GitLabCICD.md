### Runner Install

```
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
apt-get install gitlab-runner
```

### GitLab Runner Register

`gitlab-runner register`

### Runner autostart

`systemctl enable gitlab-runner.service`

#### Docker Install

```
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
```

#### Docker Runner Install and Register

```
docker run -d --name gitlab-runner --restart always \
-v /srv/gitlab-runner/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest

docker run --rm -it -v /srv/gitlab-runner/config:/etc/gitlab-runner gitlab/gitlab-runner register
```

### Ignore SSL Error
```
SERVER=gitlab.rom.home
PORT=443
CERTIFICATE=/etc/gitlab-runner/certs/${SERVER}.crt
# Create the certificates hierarchy expected by gitlab
mkdir -p $(dirname "$CERTIFICATE")
# Get the certificate in PEM format and store it
openssl s_client -connect ${SERVER}:${PORT} -showcerts </dev/null 2>/dev/null | sed -e '/-----BEGIN/,/-----END/!d' | sudo tee "$CERTIFICATE" >/dev/null
# Register your runner
gitlab-runner register --tls-ca-file="$CERTIFICATE"
```
