FROM gcc:16.2.0-trixie

# Install build tools and essentials
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    cmake \
    ninja-build \
    git \
    ccache \
    doxygen \
    curl \
		clang-tidy \
    cppcheck \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Environment paths for caching and ccache integration
ENV CPM_SOURCE_CACHE=/cache/cpm \
    CCACHE_DIR=/cache/ccache \
    CCACHE_MAXSIZE=2G \
    PATH="/usr/lib/ccache:${PATH}"

# Ensure cache directories exist with appropriate write access
RUN mkdir -p /cache/cpm /cache/ccache

EXPOSE 9200

CMD ["sh", "scripts/dev.sh"]
