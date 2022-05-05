FROM alpine:latest

COPY manage.sh /

RUN apk add openssh bash curl; \
    chmod +x /manage.sh; \
    curl -s -S -L https://git.io/get-mo -o /usr/local/bin/mo; \
    chmod +x /usr/local/bin/mo; \
    curl -s -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl; \
    chmod +x ./kubectl; \
    mv kubectl /usr/local/bin \
    curl -LO https://github.com/kvaps/kubectl-node-shell/raw/master/kubectl-node_shell \
    chmod +x ./kubectl-node_shell \
    sudo mv ./kubectl-node_shell /usr/local/bin/kubectl-node_shell

ENTRYPOINT /manage.sh
