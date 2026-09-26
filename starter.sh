#!/bin/bash

# ============================================================
# Linux Security Assignment
# Secure Departmental Directory
# ============================================================

set -e

# -----------------------------
# Configuration
# -----------------------------

GROUP_NAME="students"

USER1="student1"
USER2="student2"
UNAUTHORIZED="unauthorized"

BASE_DIR="/opt/department"
STUDENT_DIR="/opt/department/students"
TEST_FILE="/opt/department/students/student_info.txt"

# Select an appropriate SELinux type for your implementation.
SELINUX_TYPE="httpd_sys_content_t"

# Select/document an appropriate SELinux boolean.
SELINUX_BOOLEAN="httpd_enable_homedirs"

echo "======================================"
echo " Linux Security Assignment"
echo "======================================"

# ------------------------------------------------------------
# TODO 1: Check that the script is running as root
# ------------------------------------------------------------

echo "[1] Checking root privileges..."

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

# ------------------------------------------------------------
# TODO 2: Check SELinux status
# ------------------------------------------------------------

echo "[2] Checking SELinux..."

if [ "$(getenforce)" != "Enforcing" ]; then
    echo "Error: SELinux is not in Enforcing mode." >&2
    exit 1
fi

# ------------------------------------------------------------
# TODO 3: Create the students group
# ------------------------------------------------------------

echo "[3] Creating group: ${GROUP_NAME}"

if ! getent group "${GROUP_NAME}" >/dev/null; then
    groupadd "${GROUP_NAME}"
fi

# ------------------------------------------------------------
# TODO 4: Create users
# ------------------------------------------------------------

echo "[4] Creating users..."

# Create student1 and student2 belonging to the students group
if ! id "${USER1}" &>/dev/null; then
    useradd -G "\({GROUP_NAME}" "\){USER1}"
fi

if ! id "${USER2}" &>/dev/null; then
    useradd -G "\({GROUP_NAME}" "\){USER2}"
fi

# Create unauthorized user without adding to students group
if ! id "${UNAUTHORIZED}" &>/dev/null; then
    useradd "${UNAUTHORIZED}"
fi

# ------------------------------------------------------------
# TODO 5: Create departmental directory
# ------------------------------------------------------------

echo "[5] Creating directory..."

mkdir -p "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 6: Configure ownership and permissions
# ------------------------------------------------------------

echo "[6] Configuring ownership and permissions..."

# Set group ownership to 'students' and enable SGID (2770 permissions)
chown -R root:"\({GROUP_NAME}" "\){BASE_DIR}"
chmod 2770 "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 7: Create test file
# ------------------------------------------------------------

echo "[7] Creating test file..."

echo "Welcome students! Confidential student information." > "${TEST_FILE}"
chmod 0660 "${TEST_FILE}"
chown root:"\({GROUP_NAME}" "\){TEST_FILE}"

# ------------------------------------------------------------
# TODO 8: Configure persistent SELinux file context
# ------------------------------------------------------------

echo "[8] Configuring SELinux file context..."

# Add persistent file-context rule for the departmental student directory and contents
semanage fcontext -a -t "\({SELINUX_TYPE}" "\){STUDENT_DIR}(/.*)?" || semanage fcontext -m -t "\({SELINUX_TYPE}" "\){STUDENT_DIR}(/.*)?"

# Apply the context recursively using restorecon
restorecon -R -v "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 9: Configure SELinux boolean
# ------------------------------------------------------------

echo "[9] Configuring SELinux boolean..."

setsebool -P "${SELINUX_BOOLEAN}" on

# ------------------------------------------------------------
# TODO 10: Verification
# ------------------------------------------------------------

echo "[10] Verification"

echo
echo "Users:"
id "${USER1}" || true
id "${USER2}" || true
id "${UNAUTHORIZED}" || true

echo
echo "Directory:"
ls -ld "${STUDENT_DIR}" || true

echo
echo "SELinux context:"
ls -Zd "${STUDENT_DIR}" || true

echo
echo "SELinux status:"
getenforce || true

echo
echo "Selected SELinux boolean:"
if [ -n "${SELINUX_BOOLEAN}" ]; then
    getsebool "${SELINUX_BOOLEAN}" || true
else
    echo "TODO: Set SELINUX_BOOLEAN"
fi

echo
echo "======================================"
echo " Script completed"
echo "======================================"
