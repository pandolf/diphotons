#!/bin/bash

# set -x

folder=$1 && shift
coupl=$1 && shift

# echo $coupl

cd $folder

args=""
while [[ -n $1 ]]; do
    case $1 in
	-M)
	    method=$2
	    args="$args $1 $2"
	    shift
	    ;;
	-n)
	    label=$2
	    shift
	    ;;
	--hadd)
	    hadd="hadd"
	    ;;
	--dry-run)
	    dry="1"
	    ;;
	--cont)
	    cont="1"
	    ;;
	*)	    
	    args="$args $1"
	    ;;	    
    esac
    shift
done
shift


libs="-L libdiphotonsUtils"
rootversion=$(root-config --version| tr '.' ' ')
[[ $rootversion -gt 5 ]] && libs="-L libdiphotonsRooUtils"

for coup in $(echo $coupl | tr ',' ' '); do
    cards=datacard*_grav_${coup}_*.txt
    outputs=""
    
    for card in $cards; do
	echo $card
	binary=$(echo $card | sed 's%.txt$%.root%')
	signame=$(echo $card | sed 's%.*grav_%%; s%.txt%%')
	set $(echo $signame | tr '_' ' ')
	kmpl=$1
	mass=$2
	log=combine_log_${method}_${label}_${kmpl}_${mass}.log
	set -x
	if [[ -z $dry ]] && ( [[ -z $cont ]] || [[ ! -f higgsCombine${label}_k${kmpl}.${method}.mH$mass.root ]] ); then 
	    if [[ -f $binary ]] && [[ $binary -nt $card ]]; then
		card=$binary
	    fi
	    echo combine $libs $args -n "${label}_k${kmpl}" -m $mass $card > $log
	    combine $libs $args -n "${label}_k${kmpl}" -m $mass $card 2>&1 | tee -a $log
	    ## sleep 1
	fi
	set +x
	tail -5 $log 
	[[ -f higgsCombine${label}_k${kmpl}.${method}.mH$mass.root ]] && outputs="$outputs higgsCombine${label}_k${kmpl}.${method}.mH$mass.root"
    done
    if [[ -n $hadd ]]; then
	hadd -f higgsCombine${label}_k${kmpl}.$method.root $outputs
    fi
done

