{
  lib,
  writeShellScriptBin,
  cryptsetup,
  mergerfs,
  rsync,
  util-linux,
  coreutils,
  partitionUuids ? [ ],
  luksMapperPrefix ? "crypt_disk",
  diskMountBase ? "/mnt/disk",
  mergedMount ? "/mnt/disks",
  sourceDir ? "/tank",
  sudoCommand ? "doas",
  mergerfsOptions ? "cache.files=off,dropcacheonclose=false,category.create=mfs",
}:

writeShellScriptBin "luks-backup" ''
  # Configurable values
  PARTITIONS_UUIDS=(${lib.concatMapStringsSep " " (uuid: ''"${uuid}"'') partitionUuids})
  LUKS_MAPPER_PREFIX="${luksMapperPrefix}"
  DISK_MOUNT_BASE="${diskMountBase}"
  MERGED_MOUNT="${mergedMount}"
  SOURCE_DIR="${sourceDir}"
  SUDO_CMD="${sudoCommand}"
  MERGERFS_OPTIONS="${mergerfsOptions}"

  # PATH setup
  export PATH="${
    lib.makeBinPath [
      cryptsetup
      mergerfs
      rsync
      util-linux
      coreutils
    ]
  }:$PATH"

  # Global variables to track what needs cleanup
  OPENED_LUKS_CONTAINERS=()
  MOUNTED_PATHS=()
  MERGERFS_MOUNTED=false

  ################################################################################
  # CLEANUP FUNCTION
  ################################################################################

  cleanup() {
    echo
    echo "Cleaning up..."
    
    # Unmount mergerfs if it was mounted
    if [ "$MERGERFS_MOUNTED" = true ]; then
      echo "Unmounting mergerfs mount at ''${MERGED_MOUNT}..."
      ''${SUDO_CMD} umount "''${MERGED_MOUNT}" 2>/dev/null || echo "Warning: Could not unmount ''${MERGED_MOUNT}"
    fi
    
    # Unmount all mounted paths
    for mount_path in "''${MOUNTED_PATHS[@]}"; do
      echo "Unmounting ''${mount_path}..."
      ''${SUDO_CMD} umount "''${mount_path}" 2>/dev/null || echo "Warning: Could not unmount ''${mount_path}"
    done
    
    # Close all opened LUKS containers
    for mapper_name in "''${OPENED_LUKS_CONTAINERS[@]}"; do
      echo "Closing LUKS container /dev/mapper/''${mapper_name}..."
      ''${SUDO_CMD} cryptsetup close "''${mapper_name}" 2>/dev/null || echo "Warning: Could not close ''${mapper_name}"
    done
    
    echo "Cleanup completed."
  }

  ################################################################################
  # SIGNAL HANDLERS
  ################################################################################

  # Set up signal handlers for cleanup on interruption
  trap 'echo "Received interrupt signal. Cleaning up..."; cleanup; exit 130' INT TERM

  ################################################################################
  # SCRIPT START
  ################################################################################

  set -e  # Exit on any error

  # Check if partition UUIDs are provided
  if [ ''${#PARTITIONS_UUIDS[@]} -eq 0 ]; then
    echo "Error: No partition UUIDs provided. Please configure partitionUuids."
    exit 1
  fi

  # Prompt once for the LUKS passphrase (no echo)
  read -sp "Enter LUKS passphrase: " LUKS_PASSWORD
  echo  # Just to move to a new line

  ################################################################################
  # 1. OPEN & MOUNT ALL LUKS PARTITIONS
  ################################################################################

  # Counter to keep track of each disk index
  COUNTER=1
  MOUNT_PATHS=()  # Will hold each mount path to feed into mergerfs later

  for UUID in "''${PARTITIONS_UUIDS[@]}"; do
    # Convert UUID to a known device path
    PART="/dev/disk/by-uuid/''${UUID}"
    
    # Create a name for the LUKS mapping
    MAPPER_NAME="''${LUKS_MAPPER_PREFIX}''${COUNTER}"
    
    echo "Opening LUKS partition with UUID=''${UUID} as /dev/mapper/''${MAPPER_NAME}..."
    # Feed the stored passphrase into cryptsetup via stdin
    echo -n "''${LUKS_PASSWORD}" | ''${SUDO_CMD} cryptsetup open "''${PART}" "''${MAPPER_NAME}" --type luks
    
    # Track opened LUKS container for cleanup
    OPENED_LUKS_CONTAINERS+=("''${MAPPER_NAME}")
    
    # Create a mount directory for this partition
    MOUNT_DIR="''${DISK_MOUNT_BASE}''${COUNTER}"
    ''${SUDO_CMD} mkdir -p "''${MOUNT_DIR}"
    
    echo "Mounting /dev/mapper/''${MAPPER_NAME} at ''${MOUNT_DIR}..."
    ''${SUDO_CMD} mount "/dev/mapper/''${MAPPER_NAME}" "''${MOUNT_DIR}"
    
    # Track mounted path for cleanup
    MOUNTED_PATHS+=("''${MOUNT_DIR}")
    # Keep track of the mount path for mergerfs
    MOUNT_PATHS+=("''${MOUNT_DIR}")
    
    ((COUNTER++))
  done

  ################################################################################
  # 2. CREATE MERGERFS MOUNT
  ################################################################################

  # Make sure the mergerfs mount directory exists
  ''${SUDO_CMD} mkdir -p "''${MERGED_MOUNT}"

  # Join all mount paths with ':' for mergerfs
  MERGER_DIRS=''$(IFS=":"; echo "''${MOUNT_PATHS[*]}")

  echo "Creating mergerfs mount at ''${MERGED_MOUNT} combining: ''${MERGER_DIRS}"
  ''${SUDO_CMD} mergerfs "''${MERGER_DIRS}" "''${MERGED_MOUNT}" -o ''${MERGERFS_OPTIONS}

  # Mark mergerfs as mounted for cleanup tracking
  MERGERFS_MOUNTED=true

  ################################################################################
  # 3. RSYNC FROM SOURCE TO THE MERGERFS MOUNT
  ################################################################################

  echo "Copying data from ''${SOURCE_DIR} to ''${MERGED_MOUNT}..."
  ''${SUDO_CMD} rsync -avhP --delete "''${SOURCE_DIR}/" "''${MERGED_MOUNT}/"

  ################################################################################
  # 4. CLEANUP AND EXIT
  ################################################################################

  # Normal cleanup at script completion
  cleanup

  echo "All done!"
  exit 0
''
