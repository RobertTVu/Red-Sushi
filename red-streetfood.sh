#!/bin/bash
#
# Red Team-simulering
# Kurs: Incidenthantering (Frans Schartaus) - Ovning 5 / W-2
#
# ENDAST for den isolerade labb-env (Ubuntu-endpoint med Wazuh-agent + FIM).
# Scriptet simulerar en incident och Clean efter sig. Ingen funktionell
# skadlig kod - payload/reverse shell ar ofarliga marked.
#
# Kraver sudo.

set -u

# -------------------------------------------------------------------
# ---- Config -------------------------------------------------------
# -------------------------------------------------------------------

USERS=(kebab-rulle doner-rulle gyros shawarma poison-sushi-evil)
EVIL="poison-sushi-evil"
GROUP="gatubarn"
PAYLOAD="/etc/tunnel-roll-sushi-information"
CRONFILE="/etc/cron.d/sushi-tunnel"
SUDOERS="/etc/sudoers.d/$EVIL"
HOSTS_LINE="10.0.6.100 kebab-bank.se"
NFT="/etc/nftables.conf"
NFT_MARK="# bad-sushi been here and shut it down"

rand_sleep() { sleep "$((RANDOM % 3 + 1))"; }

# -------------------------------------------------------------------
# ---- Cleanup (kors alltid vid avslut via trap) -------------------
# -------------------------------------------------------------------

cleanup() {
    echo "[-] Cleanup: Restores Env..."
    sudo sed -i "\|^${HOSTS_LINE}\$|d" /etc/hosts 2>/dev/null
    sudo sed -i "\|^${NFT_MARK}\$|d" "$NFT" 2>/dev/null
    sudo rm -f "$CRONFILE" "$PAYLOAD" "$SUDOERS" 2>/dev/null
    for u in "${USERS[@]}"; do
        sudo userdel -r "$u" 2>/dev/null
    done
    sudo groupdel "$GROUP" 2>/dev/null
    echo "[-] Done. Env Restored."
}
trap cleanup EXIT

echo "====================================="
echo "[***] Startar RED TEAM-simulering"
echo "[***] Endast for lab-env"
rand_sleep

# -------------------------------------------------------------------
# ---- 1. Persistence: grupp + konton (T1136.001) -------------------
# -------------------------------------------------------------------

echo "[F] Dax att grilla kött"

sudo groupadd "$GROUP" 2>/dev/null

for u in "${USERS[@]}"; do
    sudo useradd -m -g "$GROUP" "$u" 2>/dev/null
    rand_sleep
done

# -------------------------------------------------------------------
# ---- 2. Privilege escalation: sudo till hotaktoren (T1548.003) ----
# -------------------------------------------------------------------

echo "[I] Vi ger toppings"

sudo usermod -aG sudo "$EVIL"

echo "$EVIL ALL=(ALL) NOPASSWD: ALL" | sudo tee "$SUDOERS" > /dev/null

sudo chmod 440 "$SUDOERS"
rand_sleep

# -------------------------------------------------------------------
# ---- 3. Collection: anvandarnas filer i /home ---------------------
# -------------------------------------------------------------------

echo "[$] Vi toppar lite till"

echo "Best kebab spot in Sthlm-blog" | sudo -u kebab-rulle tee /home/kebab-rulle/spot-blog.txt > /dev/null

echo "Best recipe blog" | sudo -u doner-rulle tee /home/doner-rulle/recipe-blog.txt > /dev/null

echo "Gyros-Bank user: G-Money password: tzatziki-gold" | sudo -u gyros tee /home/gyros/credentials.txt > /dev/null
rand_sleep

echo " -Frans schartaus finns en doner maste test!" | sudo -u kebab-rulle tee -a /home/kebab-rulle/spot-blog.txt > /dev/null

echo " -Meat-On-stick ska vara bra enligt rykten" | sudo -u kebab-rulle tee -a /home/kebab-rulle/spot-blog.txt > /dev/null

echo "Kan nagon generera ett bra donerrecept?" | sudo -u doner-rulle tee -a /home/doner-rulle/recipe-blog.txt > /dev/null
rand_sleep

# -------------------------------------------------------------------
# ---- 4. Noise: curl mot ofarliga tjanster -------------------------
# -------------------------------------------------------------------

echo "[H] TO much SMOOKE"

sudo -u kebab-rulle curl -s --max-time 3 "wttr.in/stockholm" > /dev/null 2>&1

sudo -u kebab-rulle curl -s --max-time 3 "parrot.live" > /dev/null 2>&1

sudo -u gyros curl -s  --max-time 3 "https://api.github.com/zen" > /dev/null 2>&1

sudo -u shawarma curl -s --max-time 3 "parrot.live" > /dev/null 2>&1
rand_sleep

# -------------------------------------------------------------------
# ---- 5. Discovery: recon av hotaktoren (T1016) --------------------
# -------------------------------------------------------------------

echo "[S] Bad-stuff-checking"

sudo -u "$EVIL" curl -s --max-time 3 "ipinfo.io" > /dev/null 2>&1
rand_sleep

# -------------------------------------------------------------------
# ---- 6. Fake-Payload + cron (T1053.003) ---------------------
# -------------------------------------------------------------------
# OBS: simulerad. Ingen funktionell reverse shell - bara en markor
#      och ett cron-jobb som kor ett ofarligt logger-meddelande.

echo "[A] Dax att marianerad nagot gott"

echo "SIMULATED reverse shell placeholder - lab only" | sudo tee "$PAYLOAD" > /dev/null

echo '0 8,16 * * 1-5 root logger -t REDTEAM_SIMULATION "simulated payload executed"' | sudo tee "$CRONFILE" > /dev/null

sudo chmod 644 "$CRONFILE"
rand_sleep

# -------------------------------------------------------------------
# ---- 7. Defense evasion: nftables-marked/ + timestomp --------------
# -------------------------------------------------------------------
# (T1562.004 Impair Defenses + T1070.006 Timestomp)

echo "[U] Some Juicy stuff "

echo "$NFT_MARK" | sudo tee -a "$NFT" > /dev/null
sudo touch -r /etc/hostname "$NFT"   # timestomp: aterstaller mtime
rand_sleep

# -------------------------------------------------------------------
# ---- 8. Impact: /etc/hosts modify-then-restore (T1565.001) --------
# -------------------------------------------------------------------

echo "[C] Tricky tricky we give pork instead lamb its cheaper"

echo "$HOSTS_LINE" | sudo tee -a /etc/hosts > /dev/null
rand_sleep

sudo sed -i "\|^${HOSTS_LINE}\$|d" /etc/hosts   # aterstaller - evasion
rand_sleep

# -------------------------------------------------------------------
# ---- 9. Exfil + wipe: las och tom credentials.txt -----------------
# -------------------------------------------------------------------
# (T1552.001 Credentials In Files + T1070.004 Indicator Removal)

echo "[E] Oh money on that cashier"

sudo cat /home/gyros/credentials.txt > /dev/null

sudo truncate -s 0 /home/gyros/credentials.txt

logger -t REDTEAM_SIMULATION "Simulated credential theft by $EVIL"
rand_sleep

echo "[***] DONE! - Happy Threat Hunting."
echo "====================================="
# cleanup kors automatiskt har via trap EXIT


# ------------------------MITRE ATT&CK-------------------------------
# --------------------------The Meny---------------------------------
# -------------------------------------------------------------------
# ---- 1. Persistence: grupp + konton (T1136.001) -------------------
# ---- 2. Privilege escalation: sudo till hotaktoren (T1548.003) ----
# ---- -. Collection: anvandarnas filer i /home ---------------------
# ---- -. Noise: curl mot ofarliga tjanster -------------------------
# ---- 3. Discovery: recon av hotaktoren (T1016) --------------------
# ---- 4. Payload: markorfil + cron (T1053.003) ---------------------
# ---- 5. Defense evasion: nftables-markor + timestomp --------------
# ----    T1562.004 Impair Defenses + T1070.006 Timestomp -----------
# ---- 6. Impact: /etc/hosts modify-then-restore (T1565.001) --------
# ---- 7. Exfil + wipe: las och tom credentials.txt -----------------
# ----    T1552.001 Credentials In Files + T1070.004 Indicator Removal
