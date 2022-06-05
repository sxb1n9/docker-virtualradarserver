# BUILDER ---------------------------------------------------------------------------------------------
FROM    debian:buster-slim AS builder

# GET VirtualRadarServer v3p7
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/VirtualRadar-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.tar.gz

# GET Plugins v3p7
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-WebAdmin-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.WebAdminPlugin.tar.gz
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-TileServerCache-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.TileServerCachePlugin.tar.gz
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-DatabaseWriter-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.DatabaseWriterPlugin.tar.gz
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-DatabaseEditor-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.DatabaseEditorPlugin.tar.gz
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-CustomContent-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.CustomContentPlugin.tar.gz
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/LanguagePack-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.LanguagePack.tar.gz

# GET New Plugins v3p7 not in v2
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-SqlServer-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.SqlServerPlugin.tar.gz
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-FeedFilter-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.FeedFilter.tar.gz

# GET Config from ASSETS
ADD     https://raw.githubusercontent.com/sxb1n9/docker-virtualradarserver/v3/assets/Configuration.xml /tmp/files/Configuration.xml

# GET Operator Logo Start Pack from ASSETS ## http://www.woodair.net/SBS/Download/LOGO.zip /tmp/files/operator-logo-starter-pack.zip # Change because of failed downloads
ADD     https://github.com/sxb1n9/docker-virtualradarserver/raw/0f76b9be40e516cf891d49bf7d4e62dca4f1e70f/assets/LOGO.zip /tmp/files/operator-logo-starter-pack.zip 

SHELL   ["/bin/bash", "-o", "pipefail", "-c"]

# DEPENDENCIES
RUN     set -x && \
        apt-get update -y && \
        apt-get install --no-install-recommends -y \
            apt-transport-https \
            ca-certificates \
            curl \
            file \
            dirmngr \
            gnupg \ 
            wget \ 
            git \
            mono-complete \
            unzip \
            uuid-runtime \
            xmlstarlet \ 
            sqlite3

# UBUNTO KEY
RUN     apt-key adv \
            --keyserver hkp://keyserver.ubuntu.com:80 \
            --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

# GET DOTNET CORE
RUN     mkdir -p dotnet && \
        cd dotnet/ && \
        wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb && \ 
        dpkg -i packages-microsoft-prod.deb && \
        rm packages-microsoft-prod.deb
RUN     apt-get update -y 
RUN     apt-get install --no-install-recommends -y dotnet-runtime-3.1 
        
# VRS STAGE
RUN     mkdir -p /opt/VirtualRadar && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.LanguagePack.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.WebAdminPlugin.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.DatabaseWriterPlugin.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.CustomContentPlugin.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.DatabaseEditorPlugin.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.TileServerCachePlugin.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.SqlServerPlugin.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.FeedFilter.tar.gz && \
        mkdir -p /config/operatorflags && \
        mkdir -p /config/silhouettes && \
        mkdir -p /config/.local && \
        mkdir -p /config/.local/share/VirtualRadar && \
        HOME=/config

# VRS PATHS Configuration.xml - Silhoettes & Flag
RUN     echo "SETTING PATHS Configuration.xml for Silhouettes and Operator Flags..." && \
        cp /tmp/files/Configuration.xml /config/.local/share/VirtualRadar/Configuration.xml && \
        cp /config/.local/share/VirtualRadar/Configuration.xml /config/.local/share/VirtualRadar/Configuration.xml.original && \
        xmlstarlet ed -s "/Configuration/BaseStationSettings" -t elem -n SilhouettesFolder -v /config/silhouettes /config/.local/share/VirtualRadar/Configuration.xml.original > /config/.local/share/VirtualRadar/Configuration.xml && \
        cp /config/.local/share/VirtualRadar/Configuration.xml /config/.local/share/VirtualRadar/Configuration.xml.original && \
        xmlstarlet ed -s "/Configuration/BaseStationSettings" -t elem -n OperatorFlagsFolder -v /config/operatorflags /config/.local/share/VirtualRadar/Configuration.xml.original > /config/.local/share/VirtualRadar/Configuration.xml && \
        rm /config/.local/share/VirtualRadar/Configuration.xml.original
        
# VRS GET Operator Flags from dedevillela
RUN     echo "Downloading Operator Flags..." && \
        git clone --depth 1 https://github.com/dedevillela/VRS-Operator-Flags.git /opt/VRS_Extras/dedevillela/VRS-Operator-Flags && \
        mv /opt/VRS_Extras/dedevillela/VRS-Operator-Flags/CustomOperatorFlags.js /opt/VRS_Extras/dedevillela/VRS-Operator-Flags/CustomOperatorFlags.js.original && \
        echo "<script>" > /opt/VRS_Extras/dedevillela/VRS-Operator-Flags/CustomOperatorFlags.js && \
        cat /opt/VRS_Extras/dedevillela/VRS-Operator-Flags/CustomOperatorFlags.js.original >> /opt/VRS_Extras/dedevillela/VRS-Operator-Flags/CustomOperatorFlags.js && \
        echo "</script>" >> /opt/VRS_Extras/dedevillela/VRS-Operator-Flags/CustomOperatorFlags.js

# VRS GET Silhoettes from dedevillela
RUN     echo "Downloading Silhouettes..." && \
        git clone --depth 1 https://github.com/dedevillela/VRS-Silhouettes.git /opt/VRS_Extras/dedevillela/VRS-Silhouettes && \
        mv /opt/VRS_Extras/dedevillela/VRS-Silhouettes/CustomSilhouette.js /opt/VRS_Extras/dedevillela/VRS-Silhouettes/CustomSilhouette.js.original && \
        echo "<script>" > /opt/VRS_Extras/dedevillela/VRS-Silhouettes/CustomSilhouette.js && \
        cat /opt/VRS_Extras/dedevillela/VRS-Silhouettes/CustomSilhouette.js.original >> /opt/VRS_Extras/dedevillela/VRS-Silhouettes/CustomSilhouette.js && \
        echo "</script>" >> /opt/VRS_Extras/dedevillela/VRS-Silhouettes/CustomSilhouette.js
        
# VRS GET Country Flags from dedevillela
RUN     echo "Downloading Country Flags..." && \
        git clone --depth 1 https://github.com/dedevillela/VRS-Country-Flags.git /opt/VRS_Extras/dedevillela/VRS-Country-Flags
        
# VRS GET Aircraft Markers from dedevillela
RUN     echo "Downloading Aircraft Markers..." && \
        git clone --depth 1 https://github.com/dedevillela/VRS-Aircraft-Markers.git /opt/VRS_Extras/dedevillela/VRS-Aircraft-Markers && \
        cp -R /opt/VRS_Extras/dedevillela/VRS-Aircraft-Markers/Web/images/markers/* /opt/VirtualRadar/Web/images/markers

# VRS GET Aviation Operator Logo Starter Pack from ASSETS
RUN     echo "Unzipping Bones Aviation Operator Logo Starter Pack..." && \
        mkdir -p /opt/VRS_Extras/bonesaviation/operator-logo-starter-pack && \
        unzip /tmp/files/operator-logo-starter-pack.zip -d /opt/VRS_Extras/bonesaviation/operator-logo-starter-pack && \
        echo "Applying Custom Content Plugin Config..." && \
        echo "VirtualRadar.Plugin.CustomContent.Options=%3c%3fxml+version%3d%221.0%22%3f%3e%0a%3cOptions+xmlns%3axsd%3d%22http%3a%2f%2fwww.w3.org%2f2001%2fXMLSchema%22+xmlns%3axsi%3d%22http%3a%2f%2fwww.w3.org%2f2001%2fXMLSchema-instance%22%3e%0a++%3cDataVersion%3e3%3c%2fDataVersion%3e%0a++%3cEnabled%3efalse%3c%2fEnabled%3e%0a++%3cInjectSettings%3e%0a++++%3cInjectSettings%3e%0a++++++%3cEnabled%3etrue%3c%2fEnabled%3e%0a++++++%3cPathAndFile%3e*%3c%2fPathAndFile%3e%0a++++++%3cInjectionLocation%3eHead%3c%2fInjectionLocation%3e%0a++++++%3cStart%3efalse%3c%2fStart%3e%0a++++++%3cFile%3e%2fopt%2fVRS_Extras%2fdedevillela%2fVRS-Operator-Flags%2fCustomOperatorFlags.js%3c%2fFile%3e%0a++++%3c%2fInjectSettings%3e%0a++++%3cInjectSettings%3e%0a++++++%3cEnabled%3etrue%3c%2fEnabled%3e%0a++++++%3cPathAndFile%3e*%3c%2fPathAndFile%3e%0a++++++%3cInjectionLocation%3eHead%3c%2fInjectionLocation%3e%0a++++++%3cStart%3efalse%3c%2fStart%3e%0a++++++%3cFile%3e%2fopt%2fVRS_Extras%2fdedevillela%2fVRS-Silhouettes%2fCustomSilhouette.js%3c%2fFile%3e%0a++++%3c%2fInjectSettings%3e%0a++++%3cInjectSettings%3e%0a++++++%3cEnabled%3etrue%3c%2fEnabled%3e%0a++++++%3cPathAndFile%3e*%3c%2fPathAndFile%3e%0a++++++%3cInjectionLocation%3eHead%3c%2fInjectionLocation%3e%0a++++++%3cStart%3efalse%3c%2fStart%3e%0a++++++%3cFile%3e%2fopt%2fVRS_Extras%2fdedevillela%2fVRS-Aircraft-Markers%2fCustomAircraftMarkers.html%3c%2fFile%3e%0a++++%3c%2fInjectSettings%3e%0a++%3c%2fInjectSettings%3e%0a%3c%2fOptions%3e" > /config/.local/share/VirtualRadar/PluginsConfiguration.txt

# FINAL -----------------------------------------------------------------------------------------------
FROM    debian:buster-slim AS final

ENV     S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
        BASESTATIONPORT=30003 \
        BEASTPORT=30005 \
        MLATPORT=30105 \
        HOME=/config

COPY    --from=builder /opt /opt
COPY    --from=builder /config /config
SHELL   ["/bin/bash", "-o", "pipefail", "-c"]

# DEPENDENCIES
RUN     set -x && \
        apt-get update -y && \
        apt-get install --no-install-recommends -y \
            apt-transport-https \
            ca-certificates \
            curl \
            file \
            dirmngr \
            gnupg \ 
            wget \ 
            git \
            mono-complete \
            unzip \
            uuid-runtime \
            xmlstarlet \ 
            sqlite3

# UBUNTO KEY
RUN     apt-key adv \
            --keyserver hkp://keyserver.ubuntu.com:80 \
            --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

# GET DOTNET CORE
RUN     mkdir -p dotnet && \
        cd dotnet/ && \
        wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb && \ 
        dpkg -i packages-microsoft-prod.deb && \
        rm packages-microsoft-prod.deb
RUN     apt-get update -y 
RUN     apt-get install --no-install-recommends -y dotnet-runtime-3.1 

# SET VRS User
RUN     echo "Create VRS User..." && \
        useradd --home-dir /home/vrs --skel /etc/skel --create-home --user-group --shell /usr/sbin/nologin vrs && \
        chown -R vrs:vrs /config

# RUN s6-overlay
RUN     echo "Install s6-overlay..." && \
        curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
        #wget -q -O /tmp/deploy-s6-overlay.sh https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh && \
        #sh /tmp/deploy-s6-overlay.sh && \
        #rm /tmp/deploy-s6-overlay.sh
    
# AUTO REMOVE & CLEAN & FOLDER DELET
RUN     echo "AUTO REMOVE & CLEAN & FOLDER DELET - STAGE 1" && \
        apt-get remove -y \
            apt-transport-https \
            file \
            gnupg
            
RUN     echo "AUTO REMOVE & CLEAN & FOLDER DELETE - STAGE 2" && \
        apt-get autoremove -y && \
        apt-get clean -y && \
        rm -rf /opt/helpers /tmp/* /var/lib/apt/lists/*

# DOCKER SETUP
COPY    etc /etc
EXPOSE  8080
VOLUME  [ "/config" ]
ENTRYPOINT [ "/init" ]
