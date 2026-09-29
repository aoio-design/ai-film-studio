#!/bin/bash
# Weekly Hermes Agent update check — SILENT when there is nothing new; prints a short
# reminder, and how to run the update from the app, only when a newer build exists.
#
# The check is the agent's own: `hermes update --check` compares what is installed against
# the branch it updates from. Do NOT compare against a container registry — this machine
# installs the agent from source, so a registry tag is a different channel and would report
# the wrong answer.
#
# Wire it up on the machine's own schedule, /config/crontabs/abc:
#   0 9 * * 1 HERMES_HOME=/agent-home/.hermes HOME=/config PATH=/config/.local/bin:/usr/local/bin:/usr/bin:/bin /config/cron-notify.sh "Update check" /agent-home/.hermes/studio/scripts/hermes-update-check.sh

OUT=$(hermes update --check 2>&1)

case "$OUT" in
  *"Update available"*)
    echo "🆕 A newer version of your Hermes Agent is available."
    echo ""
    echo "Update it from inside your cloud computer — no terminal needed:"
    echo "  open the Hermes Agent app → Settings → About → Updates →"
    echo "  click Check now, then click Update now."
    echo "  An update can take about 10 minutes or more, and the app comes back by itself."
    echo ""
    echo "Your chats, memory, skills and studio all survive the update."
    ;;
esac
exit 0
