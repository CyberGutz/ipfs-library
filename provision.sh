#!/bin/sh
# Roda no container "provider". Não tem daemon aqui: toda chamada `ipfs`
# vai pela API HTTP do container "kubo" (IPFS_API).

API="${IPFS_API:-/dns4/kubo/tcp/5001}"
LOG=/logs/provision.log
INTERVALO=21600        # re-checagem dos pins: 6h
STATUS_INTERVALO=300   # status do nó (pares, bitswap, banda): 5 min

CSV_CID=bafybeieqjjcdiz4hx3jh6txzjooqsm7bfnnbs5udnzs7gqrk4zpecrbe74
BOOKS_CID=bafybeie62easb72odjenpgkmjacw5c6kyrjkzytuxwn2qb42lhujgsajse
SITE_IPNS=k51qzi5uqu5dhw230sl4tw3i5al7nutobz1j9g0jv9yqxtia56ckfnw24hy06a

mkdir -p /logs

log() { echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }

# --api força o uso da API remota (nunca tenta abrir o repo local)
ipfs_() { ipfs --api "$API" "$@"; }

# Foto do estado do nó. Não existe "lista de quem está baixando de você" no IPFS
# (não há tracker como no torrent), mas dá para acompanhar:
#  - pares conectados (e quantos estão só via relay)
#  - bitswap: "blocks sent"/"data sent" sobem quando alguém baixa de você,
#    "partners" = pares com quem houve troca de blocos
#  - banda total de entrada/saída
status() {
  PEERS=$(ipfs_ swarm peers 2>/dev/null)
  total=$(printf '%s\n' "$PEERS" | grep -c .)
  relay=$(printf '%s\n' "$PEERS" | grep -c p2p-circuit)
  log "STATUS: $total pares conectados ($relay via relay)"
  ipfs_ bitswap stat --human 2>&1 | sed 's/^/    /' >>"$LOG"
  ipfs_ stats bw 2>&1 | sed 's/^/    /' >>"$LOG"
}

# $1 = rótulo, $2 = caminho (/ipfs/... ou /ipns/...)
# `pin add` já baixa o conteúdo e pina; se já estiver pinado, retorna rápido.
pin() {
  cid="${2#/ipfs/}"
  log "Pinando $1 ($2)"
  provs=$(ipfs_ routing findprovs --num-providers 10 --timeout 20s "$cid" 2>/dev/null | grep -c .)
  log "  provedores achados na DHT (até 10): $provs"
  if ipfs_ pin add --timeout 30m "$2" >>"$LOG" 2>&1; then
    log "OK: $1"
  else
    log "FALHOU: $1 (tento de novo no próximo ciclo)"
  fi
}

log "**** IPFSBooks bootstrap provider ****"

until ipfs_ id >/dev/null 2>&1; do
  log "Aguardando a API do kubo em $API ..."
  sleep 3
done
log "API do kubo respondeu"

PEER_ID=$(ipfs_ id -f='<id>')
log "PeerID deste nó: $PEER_ID"
log "Endereços anunciados:"
ipfs_ id -f='<addrs>' | sed 's/^/    /' | tee -a "$LOG"

status

# status periódico em segundo plano
(
  while :; do
    sleep "$STATUS_INTERVALO"
    status
  done
) &

while :; do
  pin "CSV do acervo" "/ipfs/$CSV_CID"
  pin "livros" "/ipfs/$BOOKS_CID"

  # IPNS aponta para um CID que muda: resolve e pina o CID atual.
  if SITE=$(ipfs_ name resolve --timeout 2m "/ipns/$SITE_IPNS" 2>>"$LOG"); then
    pin "homepage" "$SITE"
  else
    log "FALHOU: não consegui resolver o IPNS da homepage"
  fi

  # Não precisa de `ipfs routing provide`: o Kubo anuncia sozinho (reprovider)
  # tudo o que está no blockstore dele.
  log "Ciclo concluído. Próximo em $((INTERVALO / 3600))h"
  sleep "$INTERVALO"
done