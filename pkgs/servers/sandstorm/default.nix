{ stdenv, lib, fetchgit
, python3, zlib
, which
, libpcap, strace, curl
, discount, git, meteor
, xz, zip, unzip
, boringssl, clang, libcap, libseccomp, libsodium
, pkgsStatic
}:

stdenv.mkDerivation rec {
  pname = "sandstorm";
  version = "0.289";

  src = fetchgit {
    url = "https://github.com/sandstorm-io/sandstorm.git";
    rev = "v${version}";
    sha256 = "1fkib4k5c8039kq2dirqr2srm69z697i2qii8jrl96ywhd1p112y";
    fetchSubmodules = true;
    leaveDotGit = true;
  };

  nativeBuildInputs = [ git which ];

  buildInputs = [
    libpcap xz zip unzip
    curl python3 zlib
    meteor discount
    boringssl clang libcap libseccomp libsodium
    zlib.static pkgsStatic.libsodium
  ];

  patches = [
    ./use-system-libsodium-boringssl.patch
  ];

  postPatch = ''
    # A single capnproto test file expects to be able to write to
    # /var/tmp.  We change it to use /tmp because /var is not available
    # under nix-build.
    substituteInPlace deps/capnproto/c++/src/kj/filesystem-disk-test.c++ \
      --replace "/var/tmp" "/tmp"
  '';

  makeFlags = [
    "CC=clang"
    "CXX=clang++"
    "PARALLEL=$(NIX_BUILD_CORES)"
  ];

  # NIX_ENFORCE_PURITY prevents ld from linking against anything
  # outside of the nix store -- but ekam builds capnp locally and
  # links against it, so that causes the build to fail. So, we turn
  # this off.
  #
  # See: https://nixos.wiki/wiki/Development_environment_with_nix-shell#Troubleshooting
  preBuild = ''
    unset NIX_ENFORCE_PURITY
    makeFlagsArray+=(LIBS="$NIX_LDFLAGS")
  '';

  buildFlags = [ "fast" ];

  installPhase = ''
    mkdir $out
  '';

  meta = with lib; {
    description = "A self-hostable web productivity suite";
    longDescription = ''
      Sandstorm is an open source project built by a community of volunteers with the goal of making it really easy to run open source web applications.
    '';
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.evils ];
  };

}
