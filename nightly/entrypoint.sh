#!/bin/bash

. ${HOME}/common.sh

set -o xtrace

cd ${LIFERAY_HOME}
touch .liferay-home

envreload $1
makesymlink
copyextras

if [ "true" == "${IS_UPGRADE}" ]; then
	. ${HOME}/upgrade.sh $1
else
	. ${HOME}/bundle.sh $1
fi