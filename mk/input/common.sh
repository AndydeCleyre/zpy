t () {
  xdotool type --delay 400 "$@"
}
tab () {
  for i in $(seq 1 ${1:-1}); do
    xdotool key Tab
    sleep 1
  done
}
enter () {
  for i in $(seq 1 ${1:-1}); do
    xdotool key KP_Enter
    sleep 1
  done
}
down () {
  for i in $(seq 1 ${1:-1}); do
    xdotool key Down
    sleep 1
  done
}
