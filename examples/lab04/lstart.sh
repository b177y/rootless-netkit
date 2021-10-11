#!/bin/bash

podman kill -a
podman container prune -f
podman network prune -f

function new_net(){
    net="$1"
    mkdir -p $HOME/.config/cni/net.d
    # podman network create -d macvlan $net
    cat <<EOF > $HOME/.config/cni/net.d/$net.conflist
{
   "cniVersion": "0.4.0",
   "name": "$net",
   "plugins": [
      {
         "type": "macvlan",
         "master": ""
      }
   ]
}
EOF
}

# machine A
function start_machine(){
    machine="$1"
    networks="$2"
    echo "Starting machine $machine with networks $networks"
    podman run -d \
        --cap-add NET_ADMIN \
        --cap-add SYS_ADMIN \
        --cap-add CAP_NET_BIND_SERVICE \
        --cap-add CAP_NET_RAW \
        --cap-add CAP_SYS_NICE \
        --cap-add CAP_IPC_LOCK \
        --cap-add CAP_CHOWN \
        --hostname $machine \
        --name $machine \
        --network $networks \
        --security-opt unmask=/proc/sys \
        localhost/netkit-deb-test \
        /bin/sh -c 'while true; do sleep 30; done;'

    echo "Copying files to machine $machine"
    echo "Compressing archive"
    cd $machine; tar -cf "/tmp/$machine.tar" .; cd ..
    echo "Copying archive"
    podman cp "/tmp/$machine.tar" "$machine:/host.tar"
    echo "Extracting archive"
    podman exec $machine /bin/bash -c 'tar -xvf host.tar; rm host.tar'
    echo "Copying startup script to $machine"
    podman cp "$machine.startup" "$machine:/host.startup"
    echo "Executing host.startup"
    podman exec $machine /bin/bash /host.startup
}

function vconnect(){
    podman exec -it $1 /bin/bash
}

new_net a0d0
new_net a01
new_net a02
new_net a03
new_net a04
new_net a05
new_net a06
new_net a0d1

start_machine a0 "a0d0,a01,a02,a03,a04,a05,a06,a0d1"
start_machine dh a06
start_machine h1 a01
start_machine h2 a02
start_machine h3 a03
start_machine h4 a04
start_machine h5 a05
