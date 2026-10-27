{ config, pkgs, lib, ... }:

# Grafana Alloy via nix-darwin.
#
# METRICS-ONLY default: runs as a per-user launchd AGENT (no root needed).
#
# TO ENABLE LOG SCRAPING later:
#   1. Append the log-scraping snippet (ask for `config.alloy.logs`) to your
#      config.alloy.
#   2. Reading /var/log/*.log needs root, so switch from launchd.user.agents
#      to launchd.daemons (the commented daemon variant at the bottom).

let
  configFile = ./alloy/config.alloy;
  alloyBin   = "${pkgs.grafana-alloy}/bin/alloy";

  runScript = pkgs.writeShellScript "alloy-run" ''
    set -a
    if [ -r /etc/alloy/secrets.env ]; then
      . /etc/alloy/secrets.env
    else
      echo "ERROR: /etc/alloy/secrets.env not found or not readable" >&2
      exit 1
    fi
    set +a
    exec ${alloyBin} run \
      --storage.path="$HOME/Library/Application Support/alloy/data" \
      --server.http.listen-addr=127.0.0.1:12345 \
      ${configFile}
  '';
in
{
  environment.systemPackages = [ pkgs.grafana-alloy ];

  # Metrics-only: per-user agent, no root.
  # NOTE: /etc/alloy/secrets.env must be readable by YOUR user for this
  # agent (chown it to your user, chmod 600). Root-only 600 will NOT work
  # for a user agent — only for the root daemon variant below.
  launchd.user.agents.alloy = {
    serviceConfig = {
      ProgramArguments  = [ "${runScript}" ];
      KeepAlive         = true;
      RunAtLoad         = true;
      StandardOutPath   = "/tmp/alloy.out.log";
      StandardErrorPath = "/tmp/alloy.err.log";
    };
  };

  # --- LOG-SCRAPING VARIANT (root daemon) --------------------------------
  # Comment out launchd.user.agents.alloy above and use this instead.
  # Runs as root (can read /var/log) with system data/log paths.
  # Here the root-only 600 secrets.env is correct.
  #
  # launchd.daemons.alloy = {
  #   serviceConfig = {
  #     ProgramArguments = [
  #       "/bin/sh" "-c"
  #       ''
  #         set -a
  #         . /etc/alloy/secrets.env
  #         set +a
  #         exec ${alloyBin} run \
  #           --storage.path=/var/lib/alloy/data \
  #           --server.http.listen-addr=127.0.0.1:12345 \
  #           ${configFile}
  #       ''
  #     ];
  #     KeepAlive         = true;
  #     RunAtLoad         = true;
  #     StandardOutPath   = "/var/log/alloy/alloy.out.log";
  #     StandardErrorPath = "/var/log/alloy/alloy.err.log";
  #   };
  # };
  #
  # system.activationScripts.alloyDirs.text = ''
  #   mkdir -p /var/lib/alloy/data /var/log/alloy
  # '';
}
