#!/bin/bash -x
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

usage() {
  echo "
usage: $0 <options>
  Required not-so-options:
     --distro-dir=DIR            path to distro specific files (debian/RPM)
     --build-dir=DIR             path to hive/build/dist
     --prefix=PREFIX             path to install into

  Optional options:
     --native-build-string       eg Linux-amd-64 (optional - no native installed if not set)
     ... [ see source for more similar options ]
  "
  exit 1
}

OPTS=$(getopt \
  -n $0 \
  -o '' \
  -l 'prefix:' \
  -l 'distro-dir:' \
  -l 'source-dir:' \
  -l 'build-dir:' \
  -l 'hadoop-version:' \
  -l 'native-build-string:' \
  -l 'installed-lib-dir:' \
  -l 'hadoop-dir:' \
  -l 'httpfs-dir:' \
  -l 'hdfs-dir:' \
  -l 'yarn-dir:' \
  -l 'mapreduce-dir:' \
  -l 'client-dir:' \
  -l 'system-include-dir:' \
  -l 'system-lib-dir:' \
  -l 'system-libexec-dir:' \
  -l 'hadoop-etc-dir:' \
  -l 'httpfs-etc-dir:' \
  -l 'doc-dir:' \
  -l 'man-dir:' \
  -l 'example-dir:' \
  -l 'apache-branch:' \
  -l 'kms-dir:' \
  -l 'kms-etc-dir:' \
  -- "$@")

if [ $? != 0 ] ; then
    usage
fi

eval set -- "$OPTS"
while true ; do
    case "$1" in
        --prefix)
        PREFIX=$2 ; shift 2
        ;;
        --distro-dir)
        DISTRO_DIR=$2 ; shift 2
        ;;
        --httpfs-dir)
        HTTPFS_DIR=$2 ; shift 2
        ;;
        --hadoop-dir)
        HADOOP_DIR=$2 ; shift 2
        ;;
        --hadoop-version)
        HADOOP_VERSION=$2 ; shift 2
        ;;
        --hdfs-dir)
        HDFS_DIR=$2 ; shift 2
        ;;
        --yarn-dir)
        YARN_DIR=$2 ; shift 2
        ;;
        --mapreduce-dir)
        MAPREDUCE_DIR=$2 ; shift 2
        ;;
        --client-dir)
        CLIENT_DIR=$2 ; shift 2
        ;;
        --system-include-dir)
        SYSTEM_INCLUDE_DIR=$2 ; shift 2
        ;;
        --system-lib-dir)
        SYSTEM_LIB_DIR=$2 ; shift 2
        ;;
        --system-libexec-dir)
        SYSTEM_LIBEXEC_DIR=$2 ; shift 2
        ;;
        --build-dir)
        BUILD_DIR=$2 ; shift 2
        ;;
        --source-dir)
        SOURCE_DIR=$2 ; shift 2
        ;;
        --native-build-string)
        NATIVE_BUILD_STRING=$2 ; shift 2
        ;;
        --doc-dir)
        DOC_DIR=$2 ; shift 2
        ;;
        --hadoop-etc-dir)
        HADOOP_ETC_DIR=$2 ; shift 2
        ;;
        --httpfs-etc-dir)
        HTTPFS_ETC_DIR=$2 ; shift 2
        ;;
        --installed-lib-dir)
        INSTALLED_LIB_DIR=$2 ; shift 2
        ;;
        --man-dir)
        MAN_DIR=$2 ; shift 2
        ;;
        --example-dir)
        EXAMPLE_DIR=$2 ; shift 2
        ;;
        --kms-dir)
        KMS_DIR=$2 ; shift 2
        ;;
        --kms-etc-dir)
        KMS_ETC_DIR=$2 ; shift 2
		;;
        --)
        shift ; break
        ;;
        *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
done

for var in PREFIX BUILD_DIR; do
  if [ -z "$(eval "echo \$$var")" ]; then
    echo Missing param: $var
    usage
  fi
done

. ${DISTRO_DIR}/packaging_functions.sh

HADOOP_DIR=${HADOOP_DIR:-$PREFIX/usr/lib/hadoop}
HDFS_DIR=${HDFS_DIR:-$PREFIX/usr/lib/hadoop-hdfs}
YARN_DIR=${YARN_DIR:-$PREFIX/usr/lib/hadoop-yarn}
MAPREDUCE_DIR=${MAPREDUCE_DIR:-$PREFIX/usr/lib/hadoop-mapreduce}
CLIENT_DIR=${CLIENT_DIR:-$PREFIX/usr/lib/hadoop/client}
HTTPFS_DIR=${HTTPFS_DIR:-$PREFIX/usr/lib/hadoop-httpfs}
SYSTEM_LIB_DIR=${SYSTEM_LIB_DIR:-/usr/lib}
BIN_DIR=${BIN_DIR:-$PREFIX/usr/bin}
DOC_DIR=${DOC_DIR:-$PREFIX/usr/share/doc/hadoop}
MAN_DIR=${MAN_DIR:-$PREFIX/usr/man}
SYSTEM_INCLUDE_DIR=${SYSTEM_INCLUDE_DIR:-$PREFIX/usr/include}
SYSTEM_LIBEXEC_DIR=${SYSTEM_LIBEXEC_DIR:-$PREFIX/usr/libexec}
EXAMPLE_DIR=${EXAMPLE_DIR:-$DOC_DIR/examples}
HADOOP_ETC_DIR=${HADOOP_ETC_DIR:-$PREFIX/etc/hadoop}
HTTPFS_ETC_DIR=${HTTPFS_ETC_DIR:-$PREFIX/etc/hadoop-httpfs}
BASH_COMPLETION_DIR=${BASH_COMPLETION_DIR:-$PREFIX/etc/bash_completion.d}
KMS_DIR=${KMS_DIR:-$PREFIX/usr/lib/hadoop-kms}
KMS_ETC_DIR=${KMS_ETC_DIR:-$PREFIX/etc/hadoop-kms}

INSTALLED_HADOOP_DIR=${INSTALLED_HADOOP_DIR:-/usr/lib/hadoop}
HADOOP_NATIVE_LIB_DIR=${HADOOP_DIR}/lib/native


##Needed for some distros to find ldconfig
export PATH="/sbin/:$PATH"

# Make bin wrappers
mkdir -p $BIN_DIR

for component in $HADOOP_DIR/bin/hadoop $HDFS_DIR/bin/hdfs $YARN_DIR/bin/yarn $MAPREDUCE_DIR/bin/mapred ; do
  wrapper=$BIN_DIR/${component#*/bin/}
  case "${component}" in
    "${HADOOP_DIR}/bin/hadoop")    SET_HADOOP_LOG_DIR="";;
    "${HDFS_DIR}/bin/hdfs")        SET_HADOOP_LOG_DIR="export HADOOP_LOG_DIR=\${HADOOP_LOG_DIR:-/var/log/hadoop-hdfs}";;
    "${YARN_DIR}/bin/yarn")        SET_HADOOP_LOG_DIR="export HADOOP_LOG_DIR=\${HADOOP_LOG_DIR:-/var/log/hadoop-yarn}";;
    "${MAPREDUCE_DIR}/bin/mapred") SET_HADOOP_LOG_DIR="export HADOOP_LOG_DIR=\${HADOOP_LOG_DIR:-/var/log/hadoop-mapreduce}";;
    *)
      echo "There is a mismatch between the loop that iterates through wrapper"
      echo "scripts in install_hadoop.sh and the case statement nested inside"
      echo "it. Value not found in case statement: ${component}."
      exit 1
      ;;
  esac
  cat > $wrapper <<EOF
#!/bin/bash

# Autodetect JAVA_HOME if not defined
. /usr/lib/bigtop-utils/bigtop-detect-javahome

export HADOOP_LIBEXEC_DIR=/${SYSTEM_LIBEXEC_DIR#${PREFIX}}
${SET_HADOOP_LOG_DIR}

exec ${component#${PREFIX}} "\$@"
EOF
  chmod 755 $wrapper
done

sed -i -e "$ i export HADOOP_MAPRED_HOME=${MAPREDUCE_DIR/${PREFIX}/}\n" ${BIN_DIR}/yarn

#libexec
install -d -m 0755 ${SYSTEM_LIBEXEC_DIR}
cp -r ${BUILD_DIR}/libexec/* ${SYSTEM_LIBEXEC_DIR}/
cp ${DISTRO_DIR}/hadoop-layout.sh ${SYSTEM_LIBEXEC_DIR}/
install -m 0755 ${DISTRO_DIR}/init-hdfs.sh ${SYSTEM_LIBEXEC_DIR}/

# hadoop jar
install -d -m 0755 ${HADOOP_DIR}
cp ${BUILD_DIR}/share/hadoop/common/*.jar ${HADOOP_DIR}/
cp ${BUILD_DIR}/share/hadoop/common/lib/hadoop-auth*.jar ${HADOOP_DIR}/
cp ${BUILD_DIR}/share/hadoop/common/lib/hadoop-annotations*.jar ${HADOOP_DIR}/
install -d -m 0755 ${MAPREDUCE_DIR}
# FIXME: there is no longer a separate mapreduce lib/ folder, I guess just grab all the jars?
#cp ${BUILD_DIR}/share/hadoop/mapreduce/hadoop-mapreduce*.jar ${MAPREDUCE_DIR}
cp ${BUILD_DIR}/share/hadoop/mapreduce/*.jar ${MAPREDUCE_DIR}
cp ${BUILD_DIR}/share/hadoop/tools/lib/*.jar ${MAPREDUCE_DIR}
install -d -m 0755 ${HDFS_DIR}
cp ${BUILD_DIR}/share/hadoop/hdfs/*.jar ${HDFS_DIR}/
install -d -m 0755 ${YARN_DIR}
cp ${BUILD_DIR}/share/hadoop/yarn/hadoop-yarn*.jar ${YARN_DIR}/
chmod 644 ${HADOOP_DIR}/*.jar ${MAPREDUCE_DIR}/*.jar ${HDFS_DIR}/*.jar ${YARN_DIR}/*.jar

# Updating the client list to include aws, azure jars and their dependencies
for jar in hadoop-aws-[0-9]*.jar aws-java-sdk*.jar hadoop-azure*.jar azure-data-lake-store-sdk*.jar wildfly-openssl*.jar; do
        (cd ${MAPREDUCE_DIR} && ls $jar) >> ${BUILD_DIR}/hadoop-client.list
done

# Now, move over hadoop-aws, hadoop-azure and hadoop-azure-datalake from hadoop-mapreduce dir
mv ${MAPREDUCE_DIR}/hadoop-aws-[0-9]*.jar ${MAPREDUCE_DIR}/hadoop-azure*.jar ${HADOOP_DIR}/

install -d -m 0755 ${HADOOP_DIR}/lib
mv ${MAPREDUCE_DIR}/aws-java-sdk*.jar ${HADOOP_DIR}/lib
mv ${MAPREDUCE_DIR}/azure-data-lake-store-sdk*.jar ${HADOOP_DIR}/lib
mv ${MAPREDUCE_DIR}/wildfly-openssl*.jar ${HADOOP_DIR}/lib

# lib jars
cp ${BUILD_DIR}/share/hadoop/common/lib/*.jar ${HADOOP_DIR}/lib
#install -d -m 0755 ${MAPREDUCE_DIR}/lib
#cp ${BUILD_DIR}/share/hadoop/mapreduce/lib/*.jar ${MAPREDUCE_DIR}/lib
install -d -m 0755 ${HDFS_DIR}/lib
cp ${BUILD_DIR}/share/hadoop/hdfs/lib/*.jar ${HDFS_DIR}/lib
install -d -m 0755 ${YARN_DIR}/lib
cp ${BUILD_DIR}/share/hadoop/yarn/lib/*.jar ${YARN_DIR}/lib
install -d -m 0755 ${YARN_DIR}/timelineservice
cp ${BUILD_DIR}/share/hadoop/yarn/timelineservice/*.jar ${YARN_DIR}/timelineservice
chmod 644 ${HADOOP_DIR}/lib/*.jar ${HDFS_DIR}/lib/*.jar ${YARN_DIR}/lib/*.jar ${YARN_DIR}/timelineservice/*.jar #${YARN_DIR}/timelineservice/lib/*.jar

# Install webapps
cp -ra ${BUILD_DIR}/share/hadoop/hdfs/webapps ${HDFS_DIR}/

# bin
install -d -m 0755 ${HADOOP_DIR}/bin
cp -a ${BUILD_DIR}/bin/{hadoop,fuse_dfs} ${HADOOP_DIR}/bin
install -d -m 0755 ${HDFS_DIR}/bin
cp -a ${BUILD_DIR}/bin/hdfs ${HDFS_DIR}/bin
install -d -m 0755 ${YARN_DIR}/bin
cp -a ${BUILD_DIR}/bin/{yarn,container-executor} ${YARN_DIR}/bin
install -d -m 0755 ${MAPREDUCE_DIR}/bin
cp -a ${BUILD_DIR}/bin/mapred ${MAPREDUCE_DIR}/bin
cp -a ${BUILD_DIR}/examples/bin/* ${MAPREDUCE_DIR}/bin
# FIXME: MAPREDUCE-3980
cp -a ${BUILD_DIR}/bin/mapred ${YARN_DIR}/bin

# sbin
install -d -m 0755 ${HADOOP_DIR}/sbin
cp -a ${BUILD_DIR}/sbin/{hadoop-daemon,hadoop-daemons,workers}.sh ${HADOOP_DIR}/sbin
install -d -m 0755 ${HDFS_DIR}/sbin
cp -a ${BUILD_DIR}/sbin/{distribute-exclude,refresh-namenodes}.sh ${HDFS_DIR}/sbin
install -d -m 0755 ${YARN_DIR}/sbin
cp -a ${BUILD_DIR}/sbin/yarn-daemon.sh ${YARN_DIR}/sbin
install -d -m 0755 ${MAPREDUCE_DIR}/sbin
cp -a ${BUILD_DIR}/sbin/mr-jobhistory-daemon.sh ${MAPREDUCE_DIR}/sbin

# native libs
install -d -m 0755 ${SYSTEM_LIB_DIR}
install -d -m 0755 ${HADOOP_NATIVE_LIB_DIR}
for library in libhdfs.so.0.0.0; do
  cp ${BUILD_DIR}/lib/native/${library} ${SYSTEM_LIB_DIR}/
  ldconfig -vlN ${SYSTEM_LIB_DIR}/${library}
  ln -s ${library} ${SYSTEM_LIB_DIR}/${library/.so.*/}.so
done

install -d -m 0755 ${SYSTEM_INCLUDE_DIR}
cp ${BUILD_DIR}/include/hdfs.h ${SYSTEM_INCLUDE_DIR}/

cp ${BUILD_DIR}/lib/native/*.a ${HADOOP_NATIVE_LIB_DIR}/
for library in `cd ${BUILD_DIR}/lib/native ; ls libsnappy.so.1.* libisal.so.2.* libzstd.so.1 2>/dev/null` libhadoop.so.1.0.0 libnativetask.so.1.0.0; do
  cp ${BUILD_DIR}/lib/native/${library} ${HADOOP_NATIVE_LIB_DIR}/
  ldconfig -vlN ${HADOOP_NATIVE_LIB_DIR}/${library}
  ln -s ${library} ${HADOOP_NATIVE_LIB_DIR}/${library/.so.*/}.so
done

# Install fuse wrapper
fuse_wrapper=${BIN_DIR}/hadoop-fuse-dfs
cat > $fuse_wrapper << EOF
#!/bin/bash

/sbin/modprobe fuse

# Autodetect JAVA_HOME if not defined
. /usr/lib/bigtop-utils/bigtop-detect-javahome

export HADOOP_HOME=\${HADOOP_HOME:-${HADOOP_DIR#${PREFIX}}}

BIGTOP_DEFAULTS_DIR=\${BIGTOP_DEFAULTS_DIR-/etc/default}
[ -n "\${BIGTOP_DEFAULTS_DIR}" -a -r \${BIGTOP_DEFAULTS_DIR}/hadoop-fuse ] && . \${BIGTOP_DEFAULTS_DIR}/hadoop-fuse

export HADOOP_LIBEXEC_DIR=${SYSTEM_LIBEXEC_DIR#${PREFIX}}

if [ "\${LD_LIBRARY_PATH}" = "" ]; then
  export LD_LIBRARY_PATH=/usr/lib
  for f in \`find \${JAVA_HOME}/ -name client -prune -o -name libjvm.so -exec dirname {} \;\`; do
    export LD_LIBRARY_PATH=\$f:\${LD_LIBRARY_PATH}
  done
fi

# Pulls all jars from hadoop client package and conf files from HADOOP_CONF_DIR
for jar in \${HADOOP_HOME}/client/*.jar; do
  CLASSPATH+="\$jar:"
done
CLASSPATH+="\${HADOOP_CONF_DIR:-\${HADOOP_HOME}/etc/hadoop}"


env CLASSPATH="\${CLASSPATH}" \${HADOOP_HOME}/bin/fuse_dfs \$@
EOF

chmod 755 $fuse_wrapper

# Bash tab completion
install -d -m 0755 $BASH_COMPLETION_DIR
install -m 0644 \
  $SOURCE_DIR/hadoop-common-project/hadoop-common/src/contrib/bash-tab-completion/hadoop.sh \
  $BASH_COMPLETION_DIR/hadoop

# conf
install -d -m 0755 $HADOOP_ETC_DIR/conf.empty
cp ${DISTRO_DIR}/conf.empty/mapred-site.xml $HADOOP_ETC_DIR/conf.empty
# workaround for CDH-9780
ln -s conf.empty $HADOOP_ETC_DIR/conf.dist

cp -r ${BUILD_DIR}/etc/hadoop/* $HADOOP_ETC_DIR/conf.empty
# Remove all the windows cmd scripts
rm -f $HADOOP_ETC_DIR/*.cmd
cp $DISTRO_DIR/conf.empty/* $HADOOP_ETC_DIR/conf.empty

# docs
install -d -m 0755 ${DOC_DIR}
cp -r ${BUILD_DIR}/share/doc/* ${DOC_DIR}/

# man pages
mkdir -p $MAN_DIR/man1
for manpage in hadoop hdfs yarn mapred; do
	pigz -c < $DISTRO_DIR/$manpage.1 > $MAN_DIR/man1/$manpage.1.gz
	chmod 644 $MAN_DIR/man1/$manpage.1.gz
done

# KMS
install -d -m 0755 ${KMS_DIR}/sbin
cp ${BUILD_DIR}/sbin/kms.sh ${KMS_DIR}/sbin/
install -d -m 0755 ${PREFIX}/var/lib/hadoop-kms
install -d -m 0755 $KMS_ETC_DIR/conf.dist

mv $HADOOP_ETC_DIR/conf.empty/kms* $KMS_ETC_DIR/conf.dist
cp $HADOOP_ETC_DIR/conf.empty/core-site.xml  $KMS_ETC_DIR/conf.dist

# HTTPFS
install -d -m 0755 ${HTTPFS_DIR}/sbin
cp ${BUILD_DIR}/sbin/httpfs.sh ${HTTPFS_DIR}/sbin/
install -d -m 0755 ${PREFIX}/var/lib/hadoop-httpfs
install -d -m 0755 $HTTPFS_ETC_DIR/conf.empty

mv $HADOOP_ETC_DIR/conf.empty/httpfs* $HTTPFS_ETC_DIR/conf.empty
cp $HADOOP_ETC_DIR/conf.empty/core-site.xml $HTTPFS_ETC_DIR/conf.empty
cp $HADOOP_ETC_DIR/conf.empty/hdfs-site.xml $HTTPFS_ETC_DIR/conf.empty

# Make the pseudo-distributed config
for conf in conf.pseudo ; do
  install -d -m 0755 $HADOOP_ETC_DIR/$conf
  # Overlay the -site files
  (cd $DISTRO_DIR/$conf && tar -cf - .) | (cd $HADOOP_ETC_DIR/$conf && tar -xf -)
done
cp ${BUILD_DIR}/etc/hadoop/log4j.properties $HADOOP_ETC_DIR/conf.pseudo

# FIXME: Provide a convenience link for configuration (HADOOP-7939)
install -d -m 0755 ${HADOOP_DIR}/etc
ln -s ${HADOOP_ETC_DIR##${PREFIX}}/conf ${HADOOP_DIR}/etc/hadoop
install -d -m 0755 ${YARN_DIR}/etc
ln -s ${HADOOP_ETC_DIR##${PREFIX}}/conf ${YARN_DIR}/etc/hadoop

cp -r ${DISTRO_DIR}/conf.empty ${HADOOP_ETC_DIR}/conf.impala
rm -f ${HADOOP_ETC_DIR}/conf.impala/{mapred,capacity,container,yarn,fair-scheduler}*
IMPALA_CONFIG="\
  <property>\\n\
    <name>dfs.client.read.shortcircuit</name>\\n\
    <value>true</value>\\n\
  </property>\\n\
  <property>\\n\
    <name>dfs.domain.socket.path</name>\\n\
    <value>/var/run/hadoop-hdfs/dn._PORT</value>\\n\
  </property>\\n"
for conf_dir in ${HADOOP_ETC_DIR}/conf.impala ${HADOOP_ETC_DIR}/conf.pseudo; do
    sed -i -e "s#</configuration>#\n${IMPALA_CONFIG}\n</configuration>#" ${conf_dir}/hdfs-site.xml
done

# Create log, var and lib
install -d -m 0755 $PREFIX/var/{log,run,lib}/hadoop-hdfs
install -d -m 0755 $PREFIX/var/{log,run,lib}/hadoop-yarn
install -d -m 0755 $PREFIX/var/{log,run,lib}/hadoop-mapreduce

ln -s /var/log/hadoop-mapreduce/ ${PREFIX}/usr/lib/hadoop-mapreduce/logs

# Remove all source
for DIR in ${HADOOP_DIR} ${HDFS_DIR} ${YARN_DIR} ${MAPREDUCE_DIR} ${HTTPFS_DIR}; do
  (cd $DIR &&
   rm -fv *-sources.jar
   rm -fv lib/hadoop-*.jar)
done

# Now create a client installation area full of symlinks
install -d -m 0755 ${CLIENT_DIR}
for file in `cat ${BUILD_DIR}/hadoop-client.list` ; do
  for dir in ${HADOOP_DIR}/{lib,} ${HDFS_DIR}/{lib,} ${YARN_DIR}/{lib,} ${MAPREDUCE_DIR}; do
    [ -e $dir/$file ] && \
    ln -fs ${dir#$PREFIX}/$file ${CLIENT_DIR}/${file} && \
    ln -fs ${dir#$PREFIX}/$file ${CLIENT_DIR}/${file/-[[:digit:]]*/.jar} && \
    continue 2
  done
  exit 1
done

# slf4j-log4j will be especially prone to versioning mismatches
base_name=slf4j-log4j12
versioned_name=$base_name-[0-9].[0-9].[0-9].jar
for symlink in `find ${CLIENT_DIR} -name $base_name*.jar`; do
    if [[ $symlink =~ $versioned_name ]]; then
        rm $symlink
        continue
    fi
    target=`readlink $symlink`
    if [[ $target =~ $versioned_name ]]; then
        rm $symlink
        ln -s ${target/$versioned_name/$base_name.jar} $symlink
        continue
    fi
done

cp ./{LICENSE,NOTICE}.txt ${PREFIX}/usr/lib/hadoop-mapreduce/
cp ./{LICENSE,NOTICE}.txt ${PREFIX}/usr/lib/hadoop/
cp ./{LICENSE,NOTICE}.txt ${PREFIX}/usr/lib/hadoop-yarn/
cp ./{LICENSE,NOTICE}.txt ${PREFIX}/usr/lib/hadoop-hdfs/

# Cloudera specific
for map in hadoop_${HADOOP_DIR} hadoop-hdfs_${HDFS_DIR} hadoop-yarn_${YARN_DIR} \
           hadoop-mapreduce_${MAPREDUCE_DIR} \
           hadoop-httpfs_${HTTPFS_DIR} hadoop-kms_${KMS_DIR} ; do
  dir=${map#*_}/cloudera
  install -d -m 0755 $dir
  grep -v 'cloudera.pkg.name=' cloudera/cdh_version.properties > $dir/cdh_version.properties
  echo "cloudera.pkg.name=${map%%_*}" >> $dir/cdh_version.properties
done

internal_versionless_symlinks \
    ${HADOOP_DIR}/hadoop-*.jar \
    ${HDFS_DIR}/hadoop-*.jar \
    ${YARN_DIR}/hadoop-*.jar \
    ${MAPREDUCE_DIR}/hadoop-*.jar

external_versionless_symlinks 'hadoop' \
    ${PREFIX}/usr/lib/hadoop-mapreduce \
    ${PREFIX}/usr/lib/hadoop-yarn/lib \
    ${PREFIX}/usr/lib/hadoop/client \
    ${PREFIX}/usr/lib/hadoop/lib

# For adding extra native libs required by libhadoop.so (e.g. newer version of libcrypto.so) at run time
install -d -m 0755 ${PREFIX}/var/lib/hadoop/extra/native
