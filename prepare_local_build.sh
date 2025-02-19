#!/bin/sh -x

set -e

rebar3 get-deps

deps="_build/default/lib"





sed -i 's/DRV_CFLAGS/CFLAGS/g' $deps/epcap/rebar.config
sed -i 's/DRV_LDFLAGS/LDFLAGS/g' $deps/epcap/rebar.config


cd  $deps/osmo_map
rebar3 asn1 compile
cd ..
git clone http://cgit.osmocom.org/erlang/signerl/

cd signerl/TCAP/asn_src/ITU
make

cd ../../../../../../..
cp $deps/signerl/TCAP/asn_src/ITU/*rl $deps/osmo_sccp/src/

mkdir -p $deps/epcap/$deps
ln -sd ../../pkt $deps/epcap/$deps/pkt
mkdir -p $deps/osmo_sccp/$deps   
ln -sd ../../osmo_ss7 $deps/osmo_sccp/$deps/osmo_ss7   
ln -sd ../../epcap $deps/osmo_sccp/$deps/epcap   
ln -sd ../../pkt $deps/osmo_sccp/$deps/pkt   
ln -sd ../../signerl/MAP $deps/osmo_sccp/$deps/MAP    
ln -sd ../../signerl/SCCP $deps/osmo_sccp/$deps/SCCP   
ln -sd ../../signerl/TCAP $deps/osmo_sccp/$deps/TCAP   
mkdir -p $deps/osmo_map/$deps   
ln -sd ../../osmo_ss7 $deps/osmo_map/$deps/osmo_ss7   
ln -sd ../../epcap $deps/osmo_map/$deps/epcap   
ln -sd ../../pkt $deps/osmo_map/$deps/pkt

cp $deps/signerl/SCCP/itu/include/sccp.hrl $deps/osmo_sccp/src/   
cp $deps/signerl/TCAP/include/tcap.hrl $deps/osmo_map/src/


rebar3 compile


