#
# One way to set the JIRA HOME path is here via this variable.  Simply uncomment it and set a valid path like /jira/home.  You can of course set it outside in the command terminal.  That will also work.
#
#JIRA_HOME=""

#
#  Occasionally Atlassian Support may recommend that you set some specific JVM arguments.  You can use this variable below to do that.
#
JVM_SUPPORT_RECOMMENDED_ARGS="-Djira.jelly.on=true -Dfile.encoding=utf-8 \
-XX:MaxPermSize=512m -XX:+UseParallelOldGC -XX:+DisableExplicitGC \
-Djira.autoexport=false -Dplugin.resource.directories=/var/local/jira/contrib/scripts \
-Dmail.imap.port=993 -Dmail.imap.starttls.enable=true -Dmail.imap.socketFactory.class=javax.net.ssl.SSLSocketFactory \
-Djira.autoexport=false"

#
# The following 2 settings control the minimum and maximum given to the JIRA Java virtual machine.  In larger JIRA instances, the maximum amount will need to be increased.
#
JVM_MINIMUM_MEMORY="512M"
JVM_MAXIMUM_MEMORY="3500M"

#
# The following are the required arguments for JIRA.
#
JVM_REQUIRED_ARGS="-Djava.awt.headless=true -Datlassian.standalone=JIRA -Dorg.apache.jasper.runtime.BodyContentImpl.LIMIT_BUFFER=true -Dmail.mime.decodeparameters=true"

# Uncomment this setting if you want to import data without notifications
#
#DISABLE_NOTIFICATIONS=" -Datlassian.mail.senddisabled=true -Datlassian.mail.fetchdisabled=true -Datlassian.mail.popdisabled=true"


#-----------------------------------------------------------------------------------
#
# In general don't make changes below here
#
#-----------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------
# This allows us to actually debug GC related issues by correlating timestamps
# with other parts of the application logs.
#-----------------------------------------------------------------------------------
JVM_EXTRA_ARGS="-XX:+PrintGCDateStamps"

# JMX options should stay in CATALINA_OPTS, NOT in JVM_... parameters beacause they would prevent stop actions from running.
CATALINA_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=8081 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"

PRGDIR=`dirname "$0"`
cat "${PRGDIR}"/jirabanner.txt

JIRA_HOME_MINUSD=""
if [ "$JIRA_HOME" != "" ]; then
    echo $JIRA_HOME | grep -q " "
    if [ $? -eq 0 ]; then
	    echo ""
	    echo "--------------------------------------------------------------------------------------------------------------------"
		echo "   WARNING : You cannot have a JIRA_HOME environment variable set with spaces in it.  This variable is being ignored"
	    echo "--------------------------------------------------------------------------------------------------------------------"
    else
		JIRA_HOME_MINUSD=-Djira.home=$JIRA_HOME
    fi
fi

JAVA_OPTS="-Xms${JVM_MINIMUM_MEMORY} -Xmx${JVM_MAXIMUM_MEMORY} ${JAVA_OPTS} ${JVM_REQUIRED_ARGS} ${DISABLE_NOTIFICATIONS} ${JVM_SUPPORT_RECOMMENDED_ARGS} ${JVM_EXTRA_ARGS} ${JIRA_HOME_MINUSD}"

# Perm Gen size needs to be increased if encountering OutOfMemoryError: PermGen problems. Specifying PermGen size is not valid on IBM JDKs
JIRA_MAX_PERM_SIZE=512m
if [ -f "${PRGDIR}/permgen.sh" ]; then
    echo "Detecting JVM PermGen support..."
    . "${PRGDIR}/permgen.sh" 2>>/dev/null
    if [ $JAVA_PERMGEN_SUPPORTED = "true" ]; then
        echo "PermGen switch is supported. Setting to ${JIRA_MAX_PERM_SIZE}"
        JAVA_OPTS="-XX:MaxPermSize=${JIRA_MAX_PERM_SIZE} ${JAVA_OPTS}"
    else
        echo "PermGen switch is NOT supported and will NOT be set automatically."
    fi
fi

export JAVA_OPTS

echo ""
echo "If you encounter issues starting or stopping JIRA, please see the Troubleshooting guide at http://confluence.atlassian.com/display/JIRA/Installation+Troubleshooting+Guide"
echo ""
if [ "$JIRA_HOME_MINUSD" != "" ]; then
    echo "Using JIRA_HOME:       $JIRA_HOME"
fi

# set the location of the pid file
if [ -z "$CATALINA_PID" ] ; then
    if [ -n "$CATALINA_BASE" ] ; then
        CATALINA_PID="$CATALINA_BASE"/work/catalina.pid
    elif [ -n "$CATALINA_HOME" ] ; then
        CATALINA_PID="$CATALINA_HOME"/work/catalina.pid
    fi
fi
export CATALINA_PID

if [ -z "$CATALINA_BASE" ]; then
  if [ -z "$CATALINA_HOME" ]; then
    LOGBASE=$PRGDIR
    LOGTAIL=..
  else
    LOGBASE=$CATALINA_HOME
    LOGTAIL=.
  fi
else
  LOGBASE=$CATALINA_BASE
  LOGTAIL=.
fi

PUSHED_DIR=`pwd`
cd $LOGBASE
cd $LOGTAIL
LOGBASEABS=`pwd`
cd $PUSHED_DIR

#echo ""
echo "Server startup logs are located in $LOGBASEABS/logs/catalina.out"

