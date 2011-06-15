%define name      pktriggercord	
%define ver       0.73.01
%define rel       1
%define prefix    /usr
%define debug_package %{nil}

Summary: Remote control program for Pentax DSLR cameras.
Name: pktriggercord
Version: %ver
Release: %rel
Copyright: GPL
Group: Applications/Tools
Source: http://sourceforge.net/projects/pktriggercord/files/%ver/pkTriggerCord-%ver.src.tar.gz
URL: http://pktriggercord.sourceforge.net
BuildRoot: /var/tmp/%{name}-root
BuildArch: i386
BuildRequires: libglade2-devel
BuildRequires: gtk2-devel

%description
pkTriggerCord is a remote control program for Pentax DSLR cameras.

%prep
%setup -q

%build
make clean
make PREFIX=%{prefix}

%install
rm -rf $RPM_BUILD_ROOT
make install PREFIX=${RPM_BUILD_ROOT}/%{prefix}

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc Changelog COPYING INSTALL BUGS
%prefix/bin/*
%prefix/share/pktriggercord/*
%prefix/../etc/*

%changelog
* Sat Jun 11 2011 Andras Salamon <andras.salamon@melda.info>
- built from pkTriggerCord 0.73.00
* Wed May 25 2011 Andras Salamon <andras.salamon@melda.info>
- built from pkTriggerCord 0.72.02

