#!/bin/bash

install_jar() {
	local EXTRA_JAR="${1}/${2}.jar"

	if [ -f ${EXTRA_JAR} ]; then
		return 0
	fi

	while read -r lpkg; do
		if [ "" != "${lpkg}" ] && [ -f ${lpkg} ] && [ "" != "$(unzip -l "${lpkg}" | grep -F $2)" ]; then
			return 0
		fi
	done <<< "$(find ${LIFERAY_HOME}/osgi/marketplace -name '*.lpkg')"

	if [ "" == "${GIT_ROOT}" ] || [ "" == "${BASE_BRANCH}" ]; then
		return 0
	fi

	local PRIVATE_BRANCH=${BASE_BRANCH}

	if [[ ${PRIVATE_BRANCH} != ee-* ]] && [[ ${PRIVATE_BRANCH} != *-private ]]; then
		PRIVATE_BRANCH=${PRIVATE_BRANCH}-private
	fi

	local REFERENCE_HASH=${BASE_TAG}
	local REFERENCE_HASH_PRIVATE=${BASE_TAG}

	if [ "" == "${BASE_TAG}" ]; then
		REFERENCE_HASH=${BASE_BRANCH}
		REFERENCE_HASH_PRIVATE=${BASE_BRANCH}
	fi

	if [ "master" == "${BASE_BRANCH}" ]; then
		PRIVATE_BRANCH=7.2.x-private
		REFERENCE_HASH=7.2.x
		REFERENCE_HASH_PRIVATE=7.2.x-private
	fi

	if [[ ${REFERENCE_HASH_PRIVATE} != ee-* ]] && [[ ${REFERENCE_HASH_PRIVATE} != *-private ]]; then
		REFERENCE_HASH_PRIVATE=${REFERENCE_HASH_PRIVATE}-private
	fi

	local ARTIFACT_PROPERTIES=$(git ls-tree -r --name-only ${REFERENCE_HASH} modules/.releng | grep -F "/$3/" | grep -F artifact.properties)

	if [ "" != "${ARTIFACT_PROPERTIES}" ]; then
		local ARTIFACT_URL=$(git show ${REFERENCE_HASH}:${ARTIFACT_PROPERTIES} | grep -F artifact.url | cut -d'=' -f 2)

		echo "Downloading ${ARTIFACT_URL}"

		curl -o ${EXTRA_JAR} ${ARTIFACT_URL}

		return 0
	fi

	ARTIFACT_PROPERTIES=$(git ls-tree -r --name-only ${REFERENCE_HASH_PRIVATE} modules/.releng | grep -F "/$3/" | grep -F artifact.properties)

	if [ "" == "${ARTIFACT_PROPERTIES}" ]; then
		return 1
	fi

	local ARTIFACT_URL=$(git show ${REFERENCE_HASH_PRIVATE}:${ARTIFACT_PROPERTIES} | grep -F artifact.url | cut -d'=' -f 2)

	echo "Downloading ${ARTIFACT_URL}"

	local PRIVATE_USERNAME=$(git show ${PRIVATE_BRANCH}:working.dir.properties | grep -F "build.repository.private.username[${PRIVATE_BRANCH}]=" | cut -d'=' -f 2)
	local PRIVATE_PASSWORD=$(git show ${PRIVATE_BRANCH}:working.dir.properties | grep -F "build.repository.private.password[${PRIVATE_BRANCH}]=" | cut -d'=' -f 2)

	curl -u ${PRIVATE_USERNAME}:${PRIVATE_PASSWORD} -o ${EXTRA_JAR} ${ARTIFACT_URL}

	if ! unzip -l ${EXTRA_JAR} > /dev/null; then
		rm ${EXTRA_JAR}
	fi
}

install_jar $1 $2 $3