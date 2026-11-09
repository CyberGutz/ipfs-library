#!/usr/bin/env bash
# bench.sh — medições IPFS vs HTTP do IPFSBooks, para um Kubo instalado normalmente.
# Requisitos: bash, curl, awk e o binário `ipfs` (Kubo) no PATH.
#
#   bench.sh node-start                                   sobe um nó de TESTE isolado (repo próprio)
#   bench.sh node-stop                                    para esse nó
#   bench.sh get     <caminho-ipfs> <url-http> [N]        Teste 1 (e 5): tempo total de download
#   bench.sh ttfb    <caminho-ipfs> <url-http> [N]        Teste 4: tempo até o primeiro byte
#   bench.sh pins    <cid>...                             Teste 2: pin local + anúncio na DHT
#   bench.sh publish <arquivo> [chave-ipns]               Teste 3 (no nó de ORIGEM)
#   bench.sh watch   <cid-novo> [nome-ipns] [limite-s]    Teste 3 (no OBSERVADOR)
#   bench.sh summary [csv]                                mediana/min/max por grupo
#
# <caminho-ipfs> = /ipfs/<cid>[/arquivo]  ou só <cid>
#
# ATENÇÃO: cada rodada roda `ipfs repo gc` no nó apontado por IPFS_API, que APAGA
# todos os blocos não pinados dele. Por isso o padrão é o nó isolado do `node-start`
# (repo em ~/.ipfs-bench, API 5011, gateway 8011, swarm 4011). Não aponte para o seu
# nó principal/origem.
#
# Variáveis opcionais:
#   IPFS_API   multiaddr da API do Kubo      (padrão /ip4/127.0.0.1/tcp/5011)
#   GATEWAY    gateway HTTP do Kubo          (padrão http://127.0.0.1:8011)
#   LABEL      rótulo da série, ex. LABEL=nos-2 (o Teste 5 compara rótulos)
#   COLD=1|0   1 = antes de cada rodada: GC + desconecta os pares (padrão 1)
#   OUT        CSV de resultados             (padrão ./results/results.csv)
#   BENCH_REPO repo do nó de teste           (padrão ~/.ipfs-bench)
#   FORCE_UNPIN=1       desafixa o CID neste nó se ele estiver pinado (cuidado!)
#   EXPECTED_PEERS      PeerIDs que deveriam anunciar o CID (teste 2)
#   EXPECT_PROVIDERS    nº de provedores que encerra o "watch" (padrão 2)
#   PUBLISHED_AT        epoch impresso pelo "publish" (relógios sincronizados!)

export LC_ALL=C
set -u

API="${IPFS_API:-/ip4/127.0.0.1/tcp/5011}"
GATEWAY="${GATEWAY:-http://127.0.0.1:8011}"
LABEL="${LABEL:-sem-rotulo}"
COLD="${COLD:-1}"
OUT="${OUT:-./results/results.csv}"
BENCH_REPO="${BENCH_REPO:-$HOME/.ipfs-bench}"

usage() { sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; }

command -v ipfs >/dev/null 2>&1 || { echo "ERRO: binário 'ipfs' não encontrado no PATH" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "ERRO: 'curl' não encontrado no PATH" >&2; exit 1; }

ipfs_() { ipfs --api "$API" "$@"; }

# relógio com fração de segundo (bash 5: EPOCHREALTIME; senão date GNU; senão python3)
now() {
  if [ -n "${EPOCHREALTIME:-}" ]; then echo "$EPOCHREALTIME"; return; fi
  local t; t=$(date +%s.%N 2>/dev/null)
  case "$t" in *N*|"") python3 -c 'import time; print("%.6f" % time.time())' ;; *) echo "$t" ;; esac
}
elapsed() { awk -v a="$1" -v b="$2" 'BEGIN{printf "%.3f", b-a}'; }
norm() { case "$1" in /ipfs/*) echo "$1" ;; *) echo "/ipfs/$1" ;; esac; }
file_cid() { ipfs_ resolve -r "$1" 2>/dev/null | sed 's#^/ipfs/##'; }

# tamanho em bytes de um arquivo ou diretório
size_of() {
  if [ -d "$1" ]; then
    du -sb "$1" 2>/dev/null | cut -f1 || true
  else
    wc -c <"$1" | tr -d ' '
  fi
}

# teste rodada metodo metrica valor unidade
rec() {
  echo "$(date -u +%FT%TZ),$1,$LABEL,$2,$3,$4,$5,$6" >>"$OUT"
  printf '  %-7s %-24s %s %s\n' "$3" "$4" "$5" "$6"
}

init_csv() {
  mkdir -p "$(dirname "$OUT")"
  [ -s "$OUT" ] || echo "timestamp,teste,rotulo,rodada,metodo,metrica,valor,unidade" >"$OUT"
}

need_node() {
  ipfs_ id >/dev/null 2>&1 || {
    echo "ERRO: nenhum Kubo respondendo em $API." >&2
    echo "      Rode './bench.sh node-start' (nó de teste isolado) ou defina IPFS_API." >&2
    exit 1
  }
}

# ---------- nó de teste isolado ----------
cmd_node_start() {
  if ipfs_ id >/dev/null 2>&1; then echo "já há um nó respondendo em $API"; return 0; fi
  if [ ! -f "$BENCH_REPO/config" ]; then
    echo "criando repositório isolado em $BENCH_REPO"
    IPFS_PATH="$BENCH_REPO" ipfs init >/dev/null || exit 1
    IPFS_PATH="$BENCH_REPO" ipfs config Addresses.API /ip4/127.0.0.1/tcp/5011
    IPFS_PATH="$BENCH_REPO" ipfs config Addresses.Gateway /ip4/127.0.0.1/tcp/8011
    IPFS_PATH="$BENCH_REPO" ipfs config --json Addresses.Swarm \
      '["/ip4/0.0.0.0/tcp/4011","/ip4/0.0.0.0/udp/4011/quic-v1","/ip6/::/tcp/4011","/ip6/::/udp/4011/quic-v1"]'
    # sem mDNS: não deixa o cliente achar a origem pela LAN
    IPFS_PATH="$BENCH_REPO" ipfs config --json Discovery.MDNS.Enabled false
  fi
  IPFS_PATH="$BENCH_REPO" nohup ipfs daemon >"$BENCH_REPO/daemon.log" 2>&1 &
  local i
  for i in $(seq 1 60); do
    if ipfs_ id >/dev/null 2>&1; then
      echo "nó de teste no ar (API $API, gateway $GATEWAY, log $BENCH_REPO/daemon.log)"
      return 0
    fi
    sleep 1
  done
  echo "ERRO: o daemon não subiu; veja $BENCH_REPO/daemon.log" >&2; exit 1
}
cmd_node_stop() { ipfs_ shutdown && echo "nó de teste parado"; }

# Deixa o nó sem o conteúdo (e, com COLD=1, sem conexões) antes de cada medição.
reset_node() {
  ipfs_ repo gc >/dev/null 2>&1
  if [ "$COLD" = 1 ]; then
    ipfs_ swarm peers 2>/dev/null | while read -r a; do
      ipfs_ swarm disconnect "$a" >/dev/null 2>&1
    done
  fi
}

# Se o conteúdo estiver pinado neste nó, o GC não o remove e o teste mede disco local.
ensure_unpinned() {
  local c
  c=$(file_cid "$1")
  [ -n "$c" ] || { echo "ERRO: não consegui resolver $1" >&2; exit 1; }
  if ipfs_ pin ls --type=all "$c" >/dev/null 2>&1; then
    if [ "${FORCE_UNPIN:-0}" = 1 ]; then
      echo "AVISO: desafixando $c do nó em $API" >&2
      ipfs_ pin rm "$c" >/dev/null 2>&1
    else
      echo "ERRO: $c está pinado no nó em $API; o teste mediria disco local." >&2
      echo "      Use o nó isolado (node-start), um nó cliente sem esse pin, ou FORCE_UNPIN=1." >&2
      exit 1
    fi
  fi
}

# ---------- Teste 1 (e 5): tempo total de download ----------
cmd_get() {
  local path url n tmp i t0 t1 rc w sz_i sz_h
  path=$(norm "$1"); url="$2"; n="${3:-5}"
  need_node; init_csv
  ensure_unpinned "$path"
  tmp=$(mktemp -d)
  for i in $(seq 1 "$n"); do
    echo "rodada $i/$n"
    reset_node
    t0=$(now)
    ipfs_ get "$path" -o "$tmp/ipfs.bin" --timeout 30m >/dev/null 2>&1; rc=$?
    t1=$(now)
    if [ $rc -eq 0 ]; then
      sz_i=$(size_of "$tmp/ipfs.bin")
      rec get "$i" ipfs tempo_total "$(elapsed "$t0" "$t1")" s
      rec get "$i" ipfs tamanho "$sz_i" bytes
      rec get "$i" ipfs vazao "$(awk -v b="$sz_i" -v t="$(elapsed "$t0" "$t1")" 'BEGIN{ if (t>0) printf "%.2f", b/1048576/t; else print 0 }')" MB/s
    else
      echo "  ipfs get falhou (rc=$rc)"; rec get "$i" ipfs falha 1 flag; sz_i=0
    fi
    rm -rf "$tmp/ipfs.bin"

    w=$(curl -sS -L -o "$tmp/http.bin" -w '%{time_total} %{size_download}' "$url") || w="0 0"
    set -- $w; sz_h="$2"
    rec get "$i" http tempo_total "$1" s
    rec get "$i" http tamanho "$sz_h" bytes
    rec get "$i" http vazao "$(awk -v b="$sz_h" -v t="$1" 'BEGIN{ if (t>0) printf "%.2f", b/1048576/t; else print 0 }')" MB/s
    rm -f "$tmp/http.bin"
    [ "$sz_i" != "$sz_h" ] && echo "  AVISO: tamanhos diferentes (ipfs=$sz_i http=$sz_h): a comparação perde o sentido"
  done
  rm -rf "$tmp"
}

# ---------- Teste 4: Time To First Byte ----------
# curl -w imprime: connect pretransfer starttransfer
ttfb_curl() { curl -sS -L -o /dev/null -r 0-0 --max-time 300 -w '%{time_connect} %{time_pretransfer} %{time_starttransfer}' "$1" 2>/dev/null || true; }

cmd_ttfb() {
  local path url n cid i t0 t1 w
  path=$(norm "$1"); url="$2"; n="${3:-5}"
  need_node; init_csv
  ensure_unpinned "$path"
  cid=$(file_cid "$path")
  for i in $(seq 1 "$n"); do
    echo "rodada $i/$n"
    # a) só a DHT: tempo até achar o primeiro provedor
    reset_node
    t0=$(now); ipfs_ routing findprovs --num-providers 1 --timeout 2m "$cid" >/dev/null 2>&1; t1=$(now)
    rec ttfb "$i" ipfs dht_primeiro_provedor "$(elapsed "$t0" "$t1")" s
    # b) DHT + conexão + primeiro bloco, via gateway (mesmo curl do HTTP)
    reset_node
    w=$(ttfb_curl "$GATEWAY$path"); set -- ${w:-0 0 0}
    rec ttfb "$i" ipfs ttfb "$3" s
    rec ttfb "$i" ipfs espera_apos_conexao "$(awk -v a="$2" -v b="$3" 'BEGIN{printf "%.3f", b-a}')" s
    # c) HTTP
    w=$(ttfb_curl "$url"); set -- ${w:-0 0 0}
    rec ttfb "$i" http ttfb "$3" s
    rec ttfb "$i" http espera_apos_conexao "$(awk -v a="$2" -v b="$3" 'BEGIN{printf "%.3f", b-a}')" s
  done
}

# ---------- Teste 2: pins ----------
cmd_pins() {
  local cid provs p
  need_node; init_csv
  for cid in "$@"; do
    cid="${cid#/ipfs/}"
    echo "CID $cid"
    if ipfs_ pin ls --type=recursive "$cid" >/dev/null 2>&1; then
      rec pins 1 local pinado 1 flag
    else
      rec pins 1 local pinado 0 flag
    fi
    provs=$(ipfs_ routing findprovs --num-providers 30 --timeout 60s "$cid" 2>/dev/null)
    rec pins 1 dht provedores_achados "$(printf '%s\n' "$provs" | grep -c .)" flag
    for p in ${EXPECTED_PEERS:-}; do
      if printf '%s\n' "$provs" | grep -qx "$p"; then
        rec pins 1 "peer_${p: -6}" anunciado 1 flag
      else
        rec pins 1 "peer_${p: -6}" anunciado 0 flag
      fi
    done
  done
  echo "integridade (pin verify; vazio = nenhum pin quebrado):"
  ipfs_ pin verify --quiet 2>&1 | sed 's/^/    /'
}

# ---------- Teste 3: atualização do catálogo ----------
cmd_publish() {
  local file key cid pub fin
  file="$1"; key="${2:-}"
  need_node; init_csv
  cid=$(ipfs_ add -Q --cid-version 1 "$file") || exit 1
  pub=$(now)
  if [ -n "$key" ]; then
    ipfs_ name publish --key="$key" --timeout 5m "/ipfs/$cid" >/dev/null || exit 1
    fin=$(now)
    rec catalogo 1 origem tempo_publicar_ipns "$(elapsed "$pub" "$fin")" s
  fi
  echo "NEW_CID=$cid"
  echo "PUBLISHED_AT=$pub"
  echo "No observador: PUBLISHED_AT=$pub EXPECT_PROVIDERS=<n> ./bench.sh watch $cid <nome-ipns>"
}

cmd_watch() {
  local cid ipns limit want t0 ipns_ok max dt n r
  cid="${1#/ipfs/}"; ipns="${2:-}"; limit="${3:-1800}"; want="${EXPECT_PROVIDERS:-2}"
  need_node; init_csv
  t0="${PUBLISHED_AT:-$(now)}"; ipns_ok=0; max=0
  echo "observando $cid (alvo: $want provedores; limite ${limit}s)"
  while :; do
    dt=$(elapsed "$t0" "$(now)")
    if awk -v d="$dt" -v l="$limit" 'BEGIN{exit !(d>l)}'; then echo "limite de tempo atingido"; break; fi
    if [ -n "$ipns" ] && [ $ipns_ok -eq 0 ]; then
      r=$(ipfs_ name resolve --nocache --timeout 15s "/ipns/$ipns" 2>/dev/null)
      if [ "$r" = "/ipfs/$cid" ]; then
        ipns_ok=1; rec catalogo 1 ipns visivel_apos "$(elapsed "$t0" "$(now)")" s
      fi
    fi
    n=$(ipfs_ routing findprovs --num-providers 30 --timeout 15s "$cid" 2>/dev/null | grep -c .)
    if [ "$n" -gt "$max" ]; then
      max=$n; rec catalogo 1 dht "provedores_$n" "$(elapsed "$t0" "$(now)")" s
    fi
    if [ "$n" -ge "$want" ]; then
      if [ -z "$ipns" ] || [ $ipns_ok -eq 1 ]; then break; fi
    fi
    sleep 5
  done
  # custo de baixar a versão nova do catálogo, a partir de um nó "frio"
  reset_node
  t0=$(now)
  ipfs_ get "/ipfs/$cid" -o /tmp/catalogo.novo --timeout 10m >/dev/null 2>&1
  rec catalogo 1 ipfs obter_catalogo "$(elapsed "$t0" "$(now)")" s
  rm -rf /tmp/catalogo.novo
}

# ---------- Resumo ----------
cmd_summary() {
  local f="${1:-$OUT}"
  [ -s "$f" ] || { echo "sem resultados em $f" >&2; exit 1; }
  awk -F, 'NR>1 && $8!="bytes" && $8!="flag" {
      k=$2" | "$3" | "$5" | "$6" ("$8")"; v[k]=v[k]" "$7; c[k]++ }
    END { for (k in v) {
      m=c[k]; split(v[k], a, " ");
      for (i=2;i<=m;i++) { x=a[i]+0; j=i-1; while (j>=1 && a[j]+0>x) { a[j+1]=a[j]; j-- } a[j+1]=x }
      med=(m%2)? a[(m+1)/2] : (a[m/2]+a[m/2+1])/2;
      printf "%-62s n=%-3d min=%-9.3f mediana=%-9.3f max=%.3f\n", k, m, a[1], med, a[m] } }' "$f" | sort
}

cmd="${1:-}"; [ $# -gt 0 ] && shift
case "$cmd" in
  node-start) cmd_node_start ;;
  node-stop)  cmd_node_stop ;;
  get)     [ $# -ge 2 ] || { echo "uso: get <caminho-ipfs> <url-http> [N]" >&2; exit 2; }; cmd_get "$@" ;;
  ttfb)    [ $# -ge 2 ] || { echo "uso: ttfb <caminho-ipfs> <url-http> [N]" >&2; exit 2; }; cmd_ttfb "$@" ;;
  pins)    [ $# -ge 1 ] || { echo "uso: pins <cid>..." >&2; exit 2; }; cmd_pins "$@" ;;
  publish) [ $# -ge 1 ] || { echo "uso: publish <arquivo> [chave-ipns]" >&2; exit 2; }; cmd_publish "$@" ;;
  watch)   [ $# -ge 1 ] || { echo "uso: watch <cid-novo> [nome-ipns] [limite-s]" >&2; exit 2; }; cmd_watch "$@" ;;
  summary) cmd_summary "$@" ;;
  *) usage; exit 2 ;;
esac