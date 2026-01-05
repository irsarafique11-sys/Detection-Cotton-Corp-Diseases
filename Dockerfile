FROM eclipse-temurin:17-jdk-jammy

# Identify maintainer
LABEL maintainer="Android Build Environment"

# Set environment variables
ENV ANDROID_SDK_ROOT /opt/android-sdk-linux
ENV CMDLINE_TOOLS_ROOT ${ANDROID_SDK_ROOT}/cmdline-tools/latest
ENV PATH ${CMDLINE_TOOLS_ROOT}/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}

# Install required packages
# curl/unzip: for downloading SDK
# git: typically needed for build versioning or dependencies
# lib32stdc++6: often needed for older tools, but good practice
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Download and install Android Command Line Tools
# Version: 11076708 (latest as of typical stable usage, check specific if needed)
# Using a fixed version ensures reproducibility
RUN mkdir -p ${CMDLINE_TOOLS_ROOT} && \
    curl -o cmdline-tools.zip -L https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools/* ${CMDLINE_TOOLS_ROOT}/ && \
    rm -r ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools cmdline-tools.zip

# Accept licenses
RUN yes | sdkmanager --licenses

# Install SDK packages
# Matching compileSdk 34 and build-tools
RUN sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Set working directory
WORKDIR /app

# Copy gradle files first for caching
COPY gradle gradle
COPY gradlew .
COPY build.gradle .
COPY settings.gradle .
COPY gradle.properties .

# Copy app module
COPY app app

# Make gradlew executable
RUN chmod +x gradlew
