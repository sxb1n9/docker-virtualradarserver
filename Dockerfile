FROM    debian:buster-slim AS builder

# Download VirtualRadarServer v3p7
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/VirtualRadar-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.tar.gz

# Download Plugins v3p7
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-WebAdmin-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.WebAdminPlugin.tar.gz
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-TileServerCache-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.TileServerCachePlugin.tar.gz
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-DatabaseWriter-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.DatabaseWriterPlugin.tar.gz
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-DatabaseEditor-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.DatabaseEditorPlugin.tar.gz
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-CustomContent-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.CustomContentPlugin.tar.gz
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/LanguagePack-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.LanguagePack.tar.gz

# Download Plugins v3p7 not in v2
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-SqlServer-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.SqlServerPlugin.tar.gz
ADD     https://github.com/vradarserver/vrs/releases/download/v3.0.0-preview-7-mono/Plugin-FeedFilter-3.0.0-preview-7.tar.gz /tmp/files/VirtualRadar.FeedFilter.tar.gz

# Config is not in v3 
#ADD    http://www.virtualradarserver.co.uk/Files/VirtualRadar.exe.config.tar.gz /tmp/files/VirtualRadar.exe.config.tar.gz

# Download Operator Logo Start Pack
ADD     https://github.com/sxb1n9/docker-virtualradarserver/raw/0f76b9be40e516cf891d49bf7d4e62dca4f1e70f/assets/LOGO.zip /tmp/files/operator-logo-starter-pack.zip
# ADD   http://www.woodair.net/SBS/Download/LOGO.zip /tmp/files/operator-logo-starter-pack.zip # Change because of failed downloads

SHELL   ["/bin/bash", "-o", "pipefail", "-c"]

# Build container
# Pre-requisites
RUN     set -x && \
        apt-get update --no-install-recommends -y && \
        apt-get install --no-install-recommends -y \
            apt-transport-https \
            ca-certificates \
            dirmngr \
            gnupg
        
RUN     apt-key adv \
            --keyserver hkp://keyserver.ubuntu.com:80 \
            --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

# install .net core 3.x
RUN     apt-get install -y wget 
RUN     apt-get update; \
        apt-get install -y apt-transport-https
RUN     mkdir -p dotnet && \
        cd dotnet/ && \
        wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb && \ 
        dpkg -i packages-microsoft-prod.deb && \
        rm packages-microsoft-prod.deb
RUN     apt-get update
RUN     apt-get install -y dotnet-runtime-3.1 

# update 
RUN     apt-get update --no-install-recommends  -y && \
        apt-get install -y \
            git \
            mono-complete \
            unzip \
            uuid-runtime \
            xmlstarlet
        
# VRS stage
RUN     mkdir -p /opt/VirtualRadar && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.LanguagePack.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.WebAdminPlugin.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.DatabaseWriterPlugin.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.CustomContentPlugin.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.DatabaseEditorPlugin.tar.gz && \
        tar -C /opt/VirtualRadar -xzf /tmp/files/VirtualRadar.TileServerCachePlugin.tar.gz && \
        # tar -C /opt/VirtualRadar -xf /tmp/files/VirtualRadar.exe.config.tar.gz && \
        mkdir -p /config/operatorflags && \
        mkdir -p /config/silhouettes && \
        mkdir -p /config/.local &&\
        HOME=/config
        
# VRS 1st start
RUN     echo "Starting VirtualRadarServer for 10 seconds to allow /config to be generated..." && \
        mkdir -p /config/.local/share/VirtualRadar && \
        timeout 10 mono /opt/VirtualRadar/VirtualRadar.exe -nogui -createAdmin:"$(uuidgen -r)" -password:"$(uuidgen -r)" > /dev/null 2>&1 || true && \
        #rm /config/.local/share/VirtualRadar/Users.sqb

# VRS Silhoettes and Flag PATHS
RUN     echo "Settings Silhouettes and Flags paths..." && \
        cp /config/.local/share/VirtualRadar/Configuration.xml /config/.local/share/VirtualRadar/Configuration.xml.original && \
        xmlstarlet ed -s "/Configuration/BaseStationSettings" -t elem -n SilhouettesFolder -v /config/silhouettes /config/.local/share/VirtualRadar/Configuration.xml.original > /config/.local/share/VirtualRadar/Configuration.xml && \
        cp /config/.local/share/VirtualRadar/Configuration.xml /config/.local/share/VirtualRadar/Configuration.xml.original && \
        xmlstarlet ed -s "/Configuration/BaseStationSettings" -t elem -n OperatorFlagsFolder -v /config/operatorflags /config/.local/share/VirtualRadar/Configuration.xml.original > /config/.local/share/VirtualRadar/Configuration.xml && \
        rm /config/.local/share/VirtualRadar/Configuration.xml.original
        
# VRS Operator Flags
RUN     echo "Downloading operator flags..." && \
        git clone --depth 1 https://github.com/dedevillela/VRS-Operator-Flags.git /opt/VRS_Extras/dedevillela/VRS-Operator-Flags && \
        mv /opt/VRS_Extras/dedevillela/VRS-Operator-Flags/CustomOperatorFlags.js /opt/VRS_Extras/dedevillela/VRS-Operator-Flags/CustomOperatorFlags.js.original && \
        echo "<script>" > /opt/VRS_Extras/dedevillela/VRS-Operator-Flags/CustomOperatorFlags.js && \
        cat /opt/VRS_Extras/dedevillela/VRS-Operator-Flags/CustomOperatorFlags.js.original >> /opt/VRS_Extras/dedevillela/VRS-Operator-Flags/CustomOperatorFlags.js && \
        echo "</script>" >> /opt/VRS_Extras/dedevillela/VRS-Operator-Flags/CustomOperatorFlags.js

# VRS Silhoettes 
RUN     echo "Downloading silhouettes..." && \
        git clone --depth 1 https://github.com/dedevillela/VRS-Silhouettes.git /opt/VRS_Extras/dedevillela/VRS-Silhouettes && \
        mv /opt/VRS_Extras/dedevillela/VRS-Silhouettes/CustomSilhouette.js /opt/VRS_Extras/dedevillela/VRS-Silhouettes/CustomSilhouette.js.original && \
        echo "<script>" > /opt/VRS_Extras/dedevillela/VRS-Silhouettes/CustomSilhouette.js && \
        cat /opt/VRS_Extras/dedevillela/VRS-Silhouettes/CustomSilhouette.js.original >> /opt/VRS_Extras/dedevillela/VRS-Silhouettes/CustomSilhouette.js && \
        echo "</script>" >> /opt/VRS_Extras/dedevillela/VRS-Silhouettes/CustomSilhouette.js
        
# VRS Flags
RUN     echo "Downloading country flags..." && \
        git clone --depth 1 https://github.com/dedevillela/VRS-Country-Flags.git /opt/VRS_Extras/dedevillela/VRS-Country-Flags
        
# VRS Markers
RUN     echo "Downloading aircraft markers..." && \
        git clone --depth 1 https://github.com/dedevillela/VRS-Aircraft-Markers.git /opt/VRS_Extras/dedevillela/VRS-Aircraft-Markers && \
        cp -R /opt/VRS_Extras/dedevillela/VRS-Aircraft-Markers/Web/images/markers/* /opt/VirtualRadar/Web/images/markers

# VRS LOGO
RUN     echo "Unzipping Bones Aviation Operator Logo Starter Pack..." && \
        mkdir -p /opt/VRS_Extras/bonesaviation/operator-logo-starter-pack && \
        unzip /tmp/files/operator-logo-starter-pack.zip -d /opt/VRS_Extras/bonesaviation/operator-logo-starter-pack && \
        echo "Applying Custom Content Plugin Config..." && \
        echo "VirtualRadar.Plugin.CustomContent.Options=%3c%3fxml+version%3d%221.0%22%3f%3e%0a%3cOptions+xmlns%3axsd%3d%22http%3a%2f%2fwww.w3.org%2f2001%2fXMLSchema%22+xmlns%3axsi%3d%22http%3a%2f%2fwww.w3.org%2f2001%2fXMLSchema-instance%22%3e%0a++%3cDataVersion%3e3%3c%2fDataVersion%3e%0a++%3cEnabled%3efalse%3c%2fEnabled%3e%0a++%3cInjectSettings%3e%0a++++%3cInjectSettings%3e%0a++++++%3cEnabled%3etrue%3c%2fEnabled%3e%0a++++++%3cPathAndFile%3e*%3c%2fPathAndFile%3e%0a++++++%3cInjectionLocation%3eHead%3c%2fInjectionLocation%3e%0a++++++%3cStart%3efalse%3c%2fStart%3e%0a++++++%3cFile%3e%2fopt%2fVRS_Extras%2fdedevillela%2fVRS-Operator-Flags%2fCustomOperatorFlags.js%3c%2fFile%3e%0a++++%3c%2fInjectSettings%3e%0a++++%3cInjectSettings%3e%0a++++++%3cEnabled%3etrue%3c%2fEnabled%3e%0a++++++%3cPathAndFile%3e*%3c%2fPathAndFile%3e%0a++++++%3cInjectionLocation%3eHead%3c%2fInjectionLocation%3e%0a++++++%3cStart%3efalse%3c%2fStart%3e%0a++++++%3cFile%3e%2fopt%2fVRS_Extras%2fdedevillela%2fVRS-Silhouettes%2fCustomSilhouette.js%3c%2fFile%3e%0a++++%3c%2fInjectSettings%3e%0a++++%3cInjectSettings%3e%0a++++++%3cEnabled%3etrue%3c%2fEnabled%3e%0a++++++%3cPathAndFile%3e*%3c%2fPathAndFile%3e%0a++++++%3cInjectionLocation%3eHead%3c%2fInjectionLocation%3e%0a++++++%3cStart%3efalse%3c%2fStart%3e%0a++++++%3cFile%3e%2fopt%2fVRS_Extras%2fdedevillela%2fVRS-Aircraft-Markers%2fCustomAircraftMarkers.html%3c%2fFile%3e%0a++++%3c%2fInjectSettings%3e%0a++%3c%2fInjectSettings%3e%0a%3c%2fOptions%3e" > /config/.local/share/VirtualRadar/PluginsConfiguration.txt

# Prepare final container
FROM    debian:buster-slim AS final

ENV     S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
        BASESTATIONPORT=30003 \
        BEASTPORT=30005 \
        MLATPORT=30105 \
        HOME=/config

COPY    --from=builder /opt /opt

COPY    --from=builder /config /config

SHELL   ["/bin/bash", "-o", "pipefail", "-c"]

# Pre-requisites to install specific mono version
RUN     set -x && \
        apt-get update --no-install-recommends -y && \
        apt-get install --no-install-recommends  -y \
            apt-transport-https \
            ca-certificates \
            dirmngr \
            file \
            gnupg 
        
RUN     apt-key adv \
            --keyserver hkp://keyserver.ubuntu.com:80 \
            --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF 
    
RUN     apt-get update --no-install-recommends -y && \
        apt-get install --no-install-recommends -y \
            curl \
            mono-complete \
            sqlite3 \
            xmlstarlet
        
RUN     echo "Create vrs user..." && \
        useradd --home-dir /home/vrs --skel /etc/skel --create-home --user-group --shell /usr/sbin/nologin vrs && \
        chown -R vrs:vrs /config
    
RUN     echo "Install s6-overlay..." && \
        curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
        echo "Clean up..."
    
# Clean-up
RUN     apt-get remove -y \
            apt-transport-https \
            file \
            gnupg \
            && \
        apt-get autoremove -y && \
        apt-get clean -y && \
        rm -rf /opt/helpers /tmp/* /var/lib/apt/lists/*

COPY    etc /etc

EXPOSE  8080

VOLUME  [ "/config" ]

ENTRYPOINT [ "/init" ]
