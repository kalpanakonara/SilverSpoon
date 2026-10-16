%define _build_id_links none
%undefine __brp_mangle_shebangs
%global __os_install_post %{nil}

Name:           silverspoon
Version:        1.6.0
Release:        1%{?dist}
Summary:        SilverSpoon Linux Edition - Fast bulk downloader with Cloudflare Turnstile bypass
License:        GPL-3.0-or-later
URL:            https://github.com/kalpanakonara/SilverSpoon

# System dependencies on Linux
Requires:       (google-chrome or google-chrome-stable or chromium or /usr/bin/google-chrome)
Requires:       (p7zip or 7zip or /usr/bin/7z or /usr/bin/7za)

%description
SilverSpoon Linux Edition is a bulk downloader designed to bypass Cloudflare Turnstile
protections on file-hosting sites (like fuckingfast.co and datanodes.to)
and queue ordinary direct download links alongside them, supporting concurrent
downloading with pause, resume, inline progress, and auto-extraction.

%install
mkdir -p %{buildroot}/opt/silverspoon
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps

cp -r %{_sourcedir}/dist/silverspoon/* %{buildroot}/opt/silverspoon/
ln -sf /opt/silverspoon/silverspoon %{buildroot}/usr/bin/silverspoon

install -m 644 %{_sourcedir}/packaging/silverspoon.desktop %{buildroot}/usr/share/applications/silverspoon.desktop
install -m 644 %{_sourcedir}/SilverSpoon.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/silverspoon.png

%files
/opt/silverspoon
/usr/bin/silverspoon
/usr/share/applications/silverspoon.desktop
/usr/share/icons/hicolor/256x256/apps/silverspoon.png

%changelog
* Fri Oct 16 2026 SilverSpoon Developer <silverspoon@github.com> - 1.6.0-1
- Linux release with native Chrome Turnstile solver support.
