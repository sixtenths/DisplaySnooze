#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="${VERSION:-0.1.0}"
ARCH="${ARCH:-all}"
DIST_DIR="$ROOT_DIR/dist/linux"
WORK_DIR="$ROOT_DIR/build/linux"
INSTALL_ROOT="$WORK_DIR/install"
BIN_DIR="$INSTALL_ROOT/usr/bin"
DOC_DIR="$INSTALL_ROOT/usr/share/doc/displaysnooze"

rm -rf "$WORK_DIR"
mkdir -p "$BIN_DIR" "$DOC_DIR" "$DIST_DIR"

install -m 0755 "$ROOT_DIR/linux/displaysnooze" "$BIN_DIR/displaysnooze"
install -m 0644 "$ROOT_DIR/README.md" "$DOC_DIR/README.md"
install -m 0644 "$ROOT_DIR/LICENSE" "$DOC_DIR/LICENSE"

tar -C "$INSTALL_ROOT" -czf "$DIST_DIR/displaysnooze-${VERSION}-linux-portable.tar.gz" .

if command -v dpkg-deb >/dev/null 2>&1; then
    DEB_ROOT="$WORK_DIR/deb"
    mkdir -p "$DEB_ROOT/DEBIAN"
    cp -a "$INSTALL_ROOT/." "$DEB_ROOT/"
    cat > "$DEB_ROOT/DEBIAN/control" <<CONTROL
Package: displaysnooze
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Zac <zdksmith@yahoo.com>
Description: Turn displays off while leaving the Linux session awake
 DisplaySnooze turns displays off immediately and repeats the request for a
 short guard window so brief wake events do not light the room back up.
CONTROL
    dpkg-deb --build "$DEB_ROOT" "$DIST_DIR/displaysnooze_${VERSION}_${ARCH}.deb"
else
    echo "Skipping .deb: dpkg-deb not found" >&2
fi

if command -v rpmbuild >/dev/null 2>&1; then
    RPM_TOP="$WORK_DIR/rpmbuild"
    mkdir -p "$RPM_TOP/BUILD" "$RPM_TOP/BUILDROOT" "$RPM_TOP/RPMS" "$RPM_TOP/SOURCES" "$RPM_TOP/SPECS" "$RPM_TOP/SRPMS"
    tar -C "$ROOT_DIR" -czf "$RPM_TOP/SOURCES/displaysnooze-$VERSION.tar.gz" linux README.md LICENSE
    cat > "$RPM_TOP/SPECS/displaysnooze.spec" <<SPEC
Name: displaysnooze
Version: $VERSION
Release: 1%{?dist}
Summary: Turn displays off while leaving the Linux session awake
License: MIT
BuildArch: noarch
Source0: %{name}-%{version}.tar.gz

%description
DisplaySnooze turns displays off immediately and repeats the request for a
short guard window so brief wake events do not light the room back up.

%prep
%setup -q -c

%install
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/doc/displaysnooze
install -m 0755 linux/displaysnooze %{buildroot}/usr/bin/displaysnooze
install -m 0644 README.md %{buildroot}/usr/share/doc/displaysnooze/README.md
install -m 0644 LICENSE %{buildroot}/usr/share/doc/displaysnooze/LICENSE

%files
/usr/bin/displaysnooze
/usr/share/doc/displaysnooze/README.md
/usr/share/doc/displaysnooze/LICENSE

%changelog
* Thu Jun 25 2026 Zac <zdksmith@yahoo.com> - %{version}-1
- Initial Linux package.
SPEC
    rpmbuild --define "_topdir $RPM_TOP" -ba "$RPM_TOP/SPECS/displaysnooze.spec"
    find "$RPM_TOP/RPMS" -type f -name '*.rpm' -exec cp {} "$DIST_DIR/" \;
else
    echo "Skipping .rpm: rpmbuild not found" >&2
fi

echo "Linux packages written to $DIST_DIR"
