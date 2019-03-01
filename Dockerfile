FROM archlinux/base

# The default mirrors in archlinux/base are slow and undependable. They
# frequently fail to download packages, hence the until statement to keep
# running until the update and install of reflector succeeds. The mirrors are
# sorted base on their 'rate'.
ENV UPDATE_MIRROR_ATTEMPTS=0
RUN until \
        yes | pacman -Sy && \
        \
        # Install reflector, which is a tool for creating a pacman mirrorlist,
        pacman -S --noconfirm reflector && \
        \
        # Backup the current mirrorlist just in case.
        # TODO This shouldn't be inside the until loop.
        # TODO Just the first 2 commands should be in this until loop.
        cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup && \
        \
        # Create a new mirrorlist by sorting the last 50 mirrors to sync and
        # sort them by the download 'rate'.
        # TODO Make the number of mirrors configurable.
        reflector \
            --verbose \
            --latest 50 \
            --sort rate \
            --save /etc/pacman.d/mirrorlist || \
        \
        # This only runs if one of the previous commands failed. Therefore, we
        # increment the the attempt counter.
        ((UPDATE_MIRROR_ATTEMPTS > 5)); \
    do \
        echo -e "\n\nFailed attempt number $((UPDATE_MIRROR_ATTEMPTS+1)) to" \
                "update the mirrorlist. Trying again.\n\n"; \
        ((UPDATE_MIRROR_ATTEMPTS=UPDATE_MIRROR_ATTEMPTS+1)); \
    done && \
    \
    # Remove the reflector package and the package cache.
    pacman -Rns --noconfirm reflector

    # I was going to run this or paccache, however it looks like we've only
    # added ~7MB. The cache looks to be empty.
    #pacman -Scc --noconfirm

