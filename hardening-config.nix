# TODO: Check https://github.com/cynicsketch/nix-mineral for inspiration
{
    # Note: SSH will be allowed through the firewall thanks to the default `services.openssh.openFirewall = true;`
    networking.firewall.enable = true;

    services.fail2ban = {
        enable = true;
        # Ban IP after 5 failures
        maxretry = 5;
        ignoreIP = [
            "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16"
        ];
        bantime = "1h"; # Ban IPs for one day on the first ban
        bantime-increment = {
            enable = true; # Enable increment of bantime after each violation
            multipliers = "1 2 4 8 16 32 64";
            maxtime = "168h"; # Do not ban for more than 1 week
            overalljails = true; # Calculate the bantime based on all the violations
        };
    };
}
