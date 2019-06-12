#!/bin/bash

addmodulexml() {
	echo '<?xml version="1.0"?>

<module xmlns="urn:jboss:module:1.0" name="com.liferay.portal">
<resources>' > ${WILDFLY_HOME}/modules/com/liferay/portal/main/module.xml

	for file in $(ls -1 ${WILDFLY_HOME}/modules/com/liferay/portal/main/); do
		if [[ ${file} == *.jar ]] && [ "${file}" != "support-tomcat.jar" ]; then
			echo '<resource-root path="'${file}'" />' >> ${WILDFLY_HOME}/modules/com/liferay/portal/main/module.xml
		fi
	done

	echo '</resources>
<dependencies>
<module name="javax.api" />
<module name="javax.mail.api" />
<module name="javax.servlet.api" />
<module name="javax.servlet.jsp.api" />
<module name="javax.transaction.api" />
</dependencies>
</module>' >> ${WILDFLY_HOME}/modules/com/liferay/portal/main/module.xml
}

create_keystore() {
	return 0
}

install() {
	cd ${LIFERAY_HOME}

	local CATALINA_HOME=$(dirname $(find ${LIFERAY_HOME} -mindepth 2 -maxdepth 2 -type d -name 'webapps'))

	mkdir -p ${WILDFLY_HOME}/standalone/deployments/
	mv ${CATALINA_HOME}/webapps/ROOT ${WILDFLY_HOME}/standalone/deployments/ROOT.war

	mkdir -p ${WILDFLY_HOME}/modules/com/liferay/portal/main/

	for file in ccpp.jar hsql.jar portal-kernel.jar portlet.jar; do
		mv ${CATALINA_HOME}/lib/ext/${file} ${WILDFLY_HOME}/modules/com/liferay/portal/main/
	done

	for file in ${CATALINA_HOME}/lib/ext/com.liferay.*; do
		mv ${file} ${WILDFLY_HOME}/modules/com/liferay/portal/main/
	done

	addmodulexml

	cp ${LIFERAY_HOME}/osgi/core/com.liferay.osgi.service.tracker.collections*.jar ${WILDFLY_HOME}/modules/com/liferay/portal/main/com.liferay.osgi.service.tracker.collections.jar

	touch ${WILDFLY_HOME}/standalone/deployments/ROOT.war.dodeploy
}

makesymlink() {
	return 0
}

setup_ssl() {
	return 0
}

startserver() {
	sed -i.bak "s/-Xms[0-9MmGg]*/-Xms${JVM_HEAP_SIZE}/g" ${WILDFLY_HOME}/bin/standalone.conf
	sed -i.bak "s/-Xmx[0-9MmGg]*/-Xmx${JVM_HEAP_SIZE}/g" ${WILDFLY_HOME}/bin/standalone.conf
	sed -i.bak "s/-XX:MetaspaceSize=[0-9MmGg]*//g" ${WILDFLY_HOME}/bin/standalone.conf
	sed -i.bak "s/-XX:MaxMetaspaceSize=[0-9MmGg]*//g" ${WILDFLY_HOME}/bin/standalone.conf
	cat ${WILDFLY_HOME}/bin/standalone.conf

	/opt/jboss/wildfly/bin/standalone.sh -b 0.0.0.0 --debug 8000
}