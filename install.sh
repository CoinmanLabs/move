#!/bin/bash
while true
do

PS3='Select an action: '
options=("安装 chainflip validator" "获取节点的秘钥及地址"  "启动Chainflip node" "启动Chainflip engine" "注册Chainflip Stake验证者帐号" "退出")
select opt in "${options[@]}"
               do
                   case $opt in                           

"安装 chainflip validator")
echo "============================================================"
echo "安装开始。。。"
echo "============================================================"
	sudo apt install curl
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL repo.chainflip.io/keys/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/chainflip.gpg
    gpg --show-keys /etc/apt/keyrings/chainflip.gpg
    echo "deb [signed-by=/etc/apt/keyrings/chainflip.gpg] https://repo.chainflip.io/perseverance/ focal main" | sudo tee /etc/apt/sources.list.d/chainflip.list
    sudo apt update
    sudo apt install -y chainflip-cli chainflip-node chainflip-engine
break
;;

"获取节点的秘钥及地址")                 
# Create sui devnet directory
	read -e -p "请粘贴验证钱包的私钥private key: " YOUR_VALIDATOR_WALLET_PRIVATE_KEY
    sudo mkdir -p /etc/chainflip/keys
    echo -n "请确认您输入的private key为:"
    echo -n "$YOUR_VALIDATOR_WALLET_PRIVATE_KEY" | sudo tee /etc/chainflip/keys/ethereum_key_file
    echo -e "\n请保存好以下的私钥及各种地址------"
    chainflip-node key generate 2>&1 | tee user_save_key
    pattern=`cat user_save_key | grep "Secret seed:"`
    secret_seed=${pattern#*:}
    secret_seed=${secret_seed// /}
    echo -e -n "\nsigning_key_file:"
    echo -n "${secret_seed:2}" | sudo tee /etc/chainflip/keys/signing_key_file
    echo -e -n "\nchainflip_key:"
    sudo chainflip-node key generate-node-key --file /etc/chainflip/keys/node_key_file
    echo -e -n "node_key_file:"
    cat /etc/chainflip/keys/node_key_file
    echo -e "\n"
break
;;  


"启动Chainflip node")
read -e -p "请输入你的服务器ip: " IP_ADDRESS_OF_YOUR_NODE
    read -e -p "请输入你的alchemy RPC WEBSOCKETS地址: " WSS_ENDPOINT_FROM_ETHEREUM_CLIENT
    read -e -p "请输入你的alchemy RPC HTTPS地址: " HTTPS_ENDPOINT_FROM_ETHEREUM_CLIENT
    sudo mkdir -p /etc/chainflip/config
    echo "# Default configurations for the CFE
[node_p2p]
node_key_file = \"/etc/chainflip/keys/node_key_file\"
ip_address=\"$IP_ADDRESS_OF_YOUR_NODE\"
port = \"8078\"
[state_chain]
ws_endpoint = \"ws://127.0.0.1:9944\"
signing_key_file = \"/etc/chainflip/keys/signing_key_file\"
[eth]
# Ethereum RPC endpoints (websocket and http for redundancy).
ws_node_endpoint = \"$WSS_ENDPOINT_FROM_ETHEREUM_CLIENT\"
http_node_endpoint = \"$HTTPS_ENDPOINT_FROM_ETHEREUM_CLIENT\"
# Ethereum private key file path. This file should contain a hex-encoded private key.
private_key_file = \"/etc/chainflip/keys/ethereum_key_file\"
[signing]
db_file = \"/etc/chainflip/data.db\"" > /etc/chainflip/config/Default.toml
    sudo systemctl start chainflip-node
    tail -f /var/log/chainflip-node.log   

break
;;

"启动Chainflip engine")    
 	sudo systemctl start chainflip-engine
    sudo systemctl enable chainflip-node
    sudo systemctl enable chainflip-engine
    tail -f /var/log/chainflip-engine.log

break
;;   

"注册Chainflip Stake验证者帐号")
  read -e -p "请取一个Staking页面中验证者的别名: " validator_nickname
    sudo systemctl restart chainflip-engine
    sudo chainflip-cli \
      --config-path /etc/chainflip/config/Default.toml \
      register-account-role Validator

    sudo chainflip-cli \
    --config-path /etc/chainflip/config/Default.toml \
    activate

    sudo chainflip-cli \
    --config-path /etc/chainflip/config/Default.toml rotate

    sudo chainflip-cli \
    --config-path /etc/chainflip/config/Default.toml \
    vanity-name $validator_nickname

break
;;
"退出")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
