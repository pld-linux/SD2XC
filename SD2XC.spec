%include	/usr/lib/rpm/macros.perl
Summary:	StarDock to Xcursor
Summary(pl):	Ze StarDocka do Xcursora
Name:		SD2XC
Version:	0.0.3
Release:	1
License:	MIT
Group:		Applications
#Source0:	http://www.bwbohh.net/nohead.php?section=Files/Files&file=Software/SD2XC/%{name}-%{version}.perl&plain=0
Source0:	%{name}-%{version}.perl
URL:		http://www.bwbohh.net/?section=Software&subdir=Free/SD2XC
BuildRequires:	rpm-perlprov >= 3.0.3-16
BuildArch:	noarch
BuildRoot:	%{tmpdir}/%{name}-%{version}-root-%(id -u -n)

%description
SD2XC converts StarDock CursorXP themes (http://www.wincustomize.com/)
to XCursor themes compatable with XFree86 4.2.99 and higher.

%description -l pl
SD2XC konwertuje motywy StarDock CursorXP
(http://www.wincustomize.com/) na motywy XCursor kompatybilne z
XFree86 4.2.99 i wy¿szymi.

%install
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT%{_bindir}

install %{SOURCE0} $RPM_BUILD_ROOT%{_bindir}/%{name}

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(644,root,root,755)
%attr(755,root,root) %{_bindir}/*
