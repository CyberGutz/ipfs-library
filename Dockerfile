FROM ipfs/kubo:v0.43.1

WORKDIR /app

SHELL ["/bin/bash","-c"]

RUN ipfs --version

RUN apt-get update
RUN apt-get install -y --no-install-recomends pt
# RUN apt-get install -y --no-install-recommends git 

## Se for baixar dependências do NPM pro Helia
# DICA: requirements primeiro: só reinstala as libs quando esse arquivo muda, não a cada alteração no .py
# COPY requirements.txt /app
# RUN pip install --upgrade pip ; pip install --no-cache-dir -r requirements.txt
    
## Imagem multi-arquitetura: o buildx preenche TARGETARCH com amd64 ou arm64 (Raspberry Pi) conforme a plataforma sendo construída. O kubo usa esses mesmos nomes; o speedtest chama de x86_64 e aarch64.
ARG TARGETARCH
# RUN wget https://github.com/ipfs/kubo/releases/download/v0.43.1/kubo_v0.43.1_linux-${TARGETARCH}.tar.gz
# RUN tar -xvzf kubo_v0.43.0_linux-${TARGETARCH}.tar.gz && \
#    cd kubo && sh install.sh && cd ..  && \
#    ipfs --version

## Se previsar baixar todo seu repositório git (precisa fazer antes: apt-get install git)
# RUN git clone -b main https://github.com/CyberGutz/ipfs-library.git /TCC
# RUN mv /TCC/* /app

## caso precise salvar logs ou coisa assim (lembre-se de mapear o volume no compose)
# RUN mkdir -p /data

## Faça esse bash script que fará os ipfs get, pin, durante o build
COPY ./get-and-pin.sh /app/get-and-pin.sh
RUN chmod +x /app/get-and-pin.sh
RUN /app/get-and-pin.sh

## Faça esse bash script que fará o ipfs provide (em loop), etc
COPY ./provide.sh /app/provide.sh
RUN chmod +x /app/provide.sh

## Faz cd para a pasta raiz de onde deve-se rodar o programa
WORKDIR /app

# O que deverá ser executado quando o container for rodado (via compose)
ENTRYPOINT ["/app/provide.sh"] 
## O script ENTRYPOINT deve ter algum loop que trave o container aberto, senão ele roda 1 vez e fecha