#!/bin/bash

function merge_algo() {
    cd $HOME/tig-monorepo
    git checkout $1
    git checkout main
    git merge $1 -m "merge new algo"
    git checkout main
}

# install essential packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 snapd screen

# install rust
if [ -f "$HOME/.cargo/env" ]; then
    source $HOME/.cargo/env
else
    :
fi
if command -v rustc &> /dev/null; then
    echo "Rust 已安装. 版本: $(rustc --version)"
else
    echo "Rust 未安装. 正在安装..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source $HOME/.cargo/env
fi

# config git
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

# clone repo
if test -e $HOME/tig-monorepo; then
    cd $HOME/tig-monorepo
else
    git clone https://github.com/tig-foundation/tig-monorepo.git
    cd $HOME/tig-monorepo
fi

read -p "请输入Challenge 1算法(默认satisfiability/sat_allocd): " C1A1
C1A1=${C1A1:-"satisfiability/sat_allocd"}
merge_algo $C1A1
read -p "请输入Challenge 2算法(默认vehicle_routing/clarke_wright_super): " C2A2
C2A2=${C2A2:-"vehicle_routing/clarke_wright_super"}
merge_algo $C2A2
read -p "请输入Challenge 3算法(默认knapsack/knapmaxxing): " C3A3
C3A3=${C3A3:-"knapsack/knapmaxxing"}
merge_algo $C3A3
read -p "请输入Challenge 4算法(默认vector_search/optimax_gpu): " C4A4
C4A4=${C4A4:-"vector_search/optimax_gpu"}
merge_algo $C4A4

# build benchmarker
cd $HOME/tig-monorepo/tig-benchmarker
C1=$(echo "$C1A1" | cut -d'/' -f1)
A1=$(echo "$C1A1" | cut -d'/' -f2)
C2=$(echo "$C2A2" | cut -d'/' -f1)
A2=$(echo "$C2A2" | cut -d'/' -f2)
C3=$(echo "$C3A3" | cut -d'/' -f1)
A3=$(echo "$C3A3" | cut -d'/' -f2)
C4=$(echo "$C4A4" | cut -d'/' -f1)
A4=$(echo "$C4A4" | cut -d'/' -f2)
ALGOS_TO_COMPILE="${C1}_${A1} ${C2}_${A2} ${C3}_${A3} ${C4}_${A4}"
read -p "是否使用CUDA？(y/n): " ifcuda
ifcuda=$(echo "$ifcuda" | tr '[:upper:]' '[:lower:]')
case "$ifcuda" in
    y|yes)
	USE_CUDA='cuda'
	;;
    n|no)
	:
	;;
    *)
	echo "输入有误！"
esac
cargo build -p tig-benchmarker --release --no-default-features --features "standalone ${ALGOS_TO_COMPILE} ${USE_CUDA}"
SELECTED_ALGORITHMS='{"'"$C1"'":"'"$A1"'","'"$C2"'":"'"$A2"'","'"$C3"'":"'"$A3"'","'"$C4"'":"'"$A4"'"}'
read -p "请输入钱包地址: " ADDRESS
read -p "请输入API_KEY: " API_KEY
read -p "请输入workers(默认4): " WORKERS
WORKERS=${WORKERS:-"4"}
read -p "请输入duration(默认7500): " DURATION
DURATION=${DURATION:-"7500"}
CMD="../target/release/tig-benchmarker $ADDRESS $API_KEY '$SELECTED_ALGORITHMS' --workers $WORKERS --duration $DURATION"
read -p "请输入母机IP(若不需要直接回车): " MASTER
[[ -n "$MASTER" ]] && CMD+=" --master $MASTER"
screen -dmS tig bash -c "$CMD"
echo "------------------------挖矿已启动,请通过 screen -r tig 查看--------------------------------"
