{pkgs, ...}: {
  programs.mpv = {
    enable = true;
    config = {
      save-position-on-quit = true;
      sub-font = "Inter Variable";
      sub-font-size = 40;
      sub-border-color = "#000000";
      sub-border-size = 1.25;
      screenshot-directory = "/home/karyana/Pictures/Screenshots/mpv";
      screenshot-template = "%F-%P-%04n";
    };
    scripts = with pkgs; [mpvScripts.mpv-playlistmanager];
  };
}
