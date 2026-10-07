# Backup & Restore — provider-managed VPS backups

*Use when the owner asks what is backed up, whether a restore point exists, or how to recover the cloud computer. This buyer image has no in-container backup job. The hosting provider manages VPS backup options outside the machine; check the current hPanel listing rather than relying on an old schedule or retention promise.*

## What to check

- Open Hostinger hPanel → **VPS → Manage → Backups & Monitoring → Snapshots & Backups** and read the current backup/snapshot options, dates, and retention shown for this VPS.
- Do not claim a backup exists or is current until you have read its date and status from hPanel. Do not infer provider settings from the machine's cron list.
- The machine's own schedule is not a backup system. It carries one image-seeded line (the Cloudflare Tunnel watchdog) plus, once the studio is installed, the studio keep-alive line the agent appends. Hermes's own scheduled work runs inside the gateway's scheduler. Do not create a backup cron, mirror-to-repository job, or claim that one runs.
- The owner updates the app manually from **Settings → About → Updates**. There is no image-seeded update-check job; do not create one or promise that updates happen automatically.

## Before a restore

A provider restore may roll back the whole VPS, not just one file. Read the provider's current restore description and the selected restore point's date before proceeding. Explain that work created after that point may be lost, and ask the owner to confirm before initiating a restore. Never trigger a restore on the owner's behalf without explicit approval.

## Safe answer

If you cannot read the provider panel, say that you cannot verify the current backup status and direct the owner to the hPanel backup page. Do not replace this missing evidence with a local cron check or a remembered weekly/daily schedule.
