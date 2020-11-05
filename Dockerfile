FROM debian:stable-slim

ENV URL_REPO_DUMP978="https://github.com/flightaware/dump978.git" \
    URL_REPO_LIBUSB="https://github.com/libusb/libusb.git" \
    URL_REPO_RTLSDR="git://git.osmocom.org/rtl-sdr" \
    URL_REPO_SOAPYRTLSDR="https://github.com/pothosware/SoapyRTLSDR.git" \
    URL_REPO_SOAPYSDR="https://github.com/pothosware/SoapySDR.git" \
    BRANCH_RTLSDR="ed0317e6a58c098874ac58b769cf2e609c18d9a5"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Essentials
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(ca-certificates) && \
    TEMP_PACKAGES+=(cmake) && \
    TEMP_PACKAGES+=(curl) && \
    TEMP_PACKAGES+=(git) && \
    # s6-overlay dependencies
    TEMP_PACKAGES+=(gnupg2) && \
    TEMP_PACKAGES+=(file) && \
    # libusb (for rtl-sdr, SoapySDR)
    TEMP_PACKAGES+=(libusb-1.0-0-dev) && \
    KEPT_PACKAGES+=(libusb-1.0-0) && \
    # rtl-sdr dependencies
    TEMP_PACKAGES+=(pkg-config) && \
    # dump978 dependencies
    TEMP_PACKAGES+=(libboost-dev) && \
    TEMP_PACKAGES+=(libboost-system1.67-dev) && \
    KEPT_PACKAGES+=(libboost-system1.67.0) && \
    TEMP_PACKAGES+=(libboost-program-options1.67-dev) && \
    KEPT_PACKAGES+=(libboost-program-options1.67.0) && \
    TEMP_PACKAGES+=(libboost-regex1.67-dev) && \
    KEPT_PACKAGES+=(libboost-regex1.67.0) && \
    TEMP_PACKAGES+=(libboost-filesystem1.67-dev) && \
    KEPT_PACKAGES+=(libboost-filesystem1.67.0) && \
    # Install packages.
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ${KEPT_PACKAGES[@]} \
        ${TEMP_PACKAGES[@]} \
        && \
    git config --global advice.detachedHead false && \
    # Build & install rtl-sdr
    git clone "${URL_REPO_RTLSDR}" "/src/rtl-sdr" && \
    pushd "/src/rtl-sdr" && \
    #BRANCH_RTLSDR=$(git tag --sort="-creatordate" | head -1) && \
    #git checkout "tags/${BRANCH_RTLSDR}" && \
    git checkout "${BRANCH_RTLSDR}" && \
    echo "rtl-sdr ${BRANCH_RTLSDR}" >> /VERSIONS && \
    mkdir -p "/src/rtl-sdr/build" && \
    pushd "/src/rtl-sdr/build" && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -Wno-dev -DCMAKE_BUILD_TYPE=Release && \
    make -Wstringop-truncation && \
    make -Wstringop-truncation install && \
    cp -v "/src/rtl-sdr/rtl-sdr.rules" "/etc/udev/rules.d/" && \
    ldconfig && \
    popd && popd && \
    # Build & install SoapySDR
    git clone "${URL_REPO_SOAPYSDR}" "/src/SoapySDR" && \
    pushd "/src/SoapySDR" && \
    BRANCH_SOAPYSDR=$(git tag --sort="-creatordate" | head -1) && \
    git checkout "${BRANCH_SOAPYSDR}" && \
    mkdir -p "/src/SoapySDR/build" && \
    pushd "/src/SoapySDR/build" && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make && \
    make test && \
    make install && \
    ldconfig && \
    echo "SoapySDR $(SoapySDRUtil --info | grep -i 'lib version:' | cut -d ':' -f 2 | tr -d ' ')" >> /VERSIONS && \
    # Build & install SoapyRTLSDR
    git clone "${URL_REPO_SOAPYRTLSDR}" "/src/SoapyRTLSDR" && \
    pushd "/src/SoapyRTLSDR" && \
    BRANCH_SOAPYRTLSDR=$(git tag --sort="-creatordate" | head -1) && \
    git checkout "${BRANCH_SOAPYRTLSDR}" && \
    echo "SoapyRTLSDR ${BRANCH_SOAPYRTLSDR}" >> /VERSIONS && \
    mkdir -p "/src/SoapyRTLSDR/build" && \
    pushd "/src/SoapyRTLSDR/build" && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make && \
    make install && \
    popd && popd && \
    # Build & install dump978
    git clone "${URL_REPO_DUMP978}" "/src/dump978" && \
    pushd "/src/dump978" && \
    BRANCH_DUMP978=$(git tag --sort="-creatordate" | head -1) && \
    git checkout "${BRANCH_DUMP978}" && \
    make all faup978 && \
    mkdir -p "/usr/lib/piaware/helpers" && \
    cp -v dump978-fa skyaware978 "/usr/local/bin/" && \
    cp -v faup978 "/usr/lib/piaware/helpers/" && \
    mkdir -p "/usr/share/dump978-fa/html" && \
    cp -a "/src/dump978/skyaware/"* "/usr/share/dump978-fa/html/" && \
    popd && \
    # Deploy s6-overlay.
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    # Clean up
    apt-get remove -y ${TEMP_PACKAGES[@]} && \
    apt-get autoremove -y && \
    # rm -rf /src/* /tmp/* /var/lib/apt/lists/* && \
    # Print versions
    cat /VERSIONS

# TODO
#  - add s6-overlay & scripts
#  - work out a way to test - maybe capture some output and parse it?
