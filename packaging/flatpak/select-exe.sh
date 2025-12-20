#!/bin/bash
novadoom_client() {
    command novadoom "$@"
}

novadoom_server() {
    command novasrv "$@"
}

novadoom_launcher() {
    command novalaunch "$@"
}

if declare -f "novadoom_$1" >/dev/null; then
    func="novadoom_$1"
    shift
    "$func" "$@"
else
    echo -e "\e[4mUsage:\e[0m flatpak run net.novadoom.NovaDoom <COMMAND>"
    echo
    echo -e "\e[4mCommands:\e[0m"
    echo "  client"
    echo "  server"
    echo "  launcher"
    exit 1
fi
